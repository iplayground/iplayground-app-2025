import OSLog
import SwiftUI

private let logger = Logger(subsystem: "Views", category: "CachedAsyncImage")

private enum ImageLoadingState: Equatable {
  case idle
  case loading
  case loaded(UIImage)
  case failed
}

package struct CachedAsyncImage<Content>: View where Content: View {
  private let url: URL?
  private let content: (AsyncImagePhase) -> Content
  @State private var loadingState: ImageLoadingState = .idle

  package init(
    url: URL?,
    @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
  ) {
    self.url = url
    self.content = content
  }

  package var body: some View {
    Group {
      switch loadingState {
      case .idle:
        content(url != nil ? .empty : .failure(URLError(.badURL)))
      case .loading:
        content(.empty)
      case .loaded(let image):
        content(.success(Image(uiImage: image)))
      case .failed:
        content(.empty)  // Gracefully show placeholder, don't expose technical errors
      }
    }
    .task(id: url) {
      await loadImage()
    }
  }

  @MainActor
  private func loadImage() async {
    guard let url = url else {
      loadingState = .idle
      return
    }

    // Check if image is already cached
    if let cachedImage = await ImageCacheManager.shared.cachedImage(for: url) {
      logger.debug("Using cached image for URL: \(url.absoluteString)")
      loadingState = .loaded(cachedImage)
      return
    }

    // Don't start loading if already in progress
    if case .loading = loadingState {
      return
    }

    loadingState = .loading
    logger.debug("Loading image from URL: \(url.absoluteString)")

    do {
      let loadedImage = try await ImageCacheManager.shared.loadImage(from: url)
      loadingState = .loaded(loadedImage)
      logger.debug("Successfully loaded image from URL: \(url.absoluteString)")
    } catch {
      logger.error(
        "Failed to load image from URL \(url.absoluteString): \(error.localizedDescription)")
      loadingState = .failed
    }
  }
}

extension CachedAsyncImage {
  package init(url: URL?) where Content == Image {
    self.url = url
    self.content = { phase in
      switch phase {
      case let .success(image):
        image
      default:
        Image(systemName: "photo")
      }
    }
  }
}

@MainActor
private class ImageCacheManager {
  static let shared = ImageCacheManager()

  private let memoryCache = NSCache<NSURL, UIImage>()
  private let urlCache: URLCache
  private let imageSession: URLSession
  private var loadingTasks: [URL: Task<UIImage, Error>] = [:]
  private let logger = Logger(subsystem: "iPlayground", category: "ImageCacheManager")

  private init() {
    // Configure memory cache
    memoryCache.countLimit = 100
    memoryCache.totalCostLimit = 50 * 1024 * 1024  // 50MB

    // Configure URL cache for disk storage
    let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
      .appendingPathComponent("ImageCache")

    do {
      try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    } catch {
      logger.error("Failed to create cache directory: \(error.localizedDescription)")
    }

    urlCache = URLCache(
      memoryCapacity: 10 * 1024 * 1024,  // 10MB memory
      diskCapacity: 100 * 1024 * 1024,  // 100MB disk
      directory: cacheDirectory
    )

    // Configure dedicated image session for optimal performance
    let sessionConfig = URLSessionConfiguration.default
    sessionConfig.httpMaximumConnectionsPerHost = 8  // More concurrent image downloads
    sessionConfig.requestCachePolicy = .returnCacheDataElseLoad
    sessionConfig.urlCache = urlCache
    sessionConfig.timeoutIntervalForRequest = 30
    sessionConfig.timeoutIntervalForResource = 60
    imageSession = URLSession(configuration: sessionConfig)

    // Setup memory warning and lifecycle observers
    setupLifecycleObservers()

    logger.info(
      "ImageCacheManager initialized with memory limit: \(self.memoryCache.totalCostLimit / 1024 / 1024)MB, max connections: \(sessionConfig.httpMaximumConnectionsPerHost)"
    )
  }

  func cachedImage(for url: URL) async -> UIImage? {
    // First check memory cache
    if let cachedImage = memoryCache.object(forKey: url as NSURL) {
      return cachedImage
    }

    // Then check disk cache
    let request = URLRequest(url: url)
    if let cachedResponse = urlCache.cachedResponse(for: request),
      let image = UIImage(data: cachedResponse.data)
    {
      // Store in memory cache for faster access
      memoryCache.setObject(image, forKey: url as NSURL)
      return image
    }

    return nil
  }

  private func setupLifecycleObservers() {
    // Clear cache on memory warning
    NotificationCenter.default.addObserver(
      forName: UIApplication.didReceiveMemoryWarningNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.logger.warning("Memory warning received, clearing image cache")
        self?.clearCache()
      }
    }

    // Partial cleanup when app goes to background
    NotificationCenter.default.addObserver(
      forName: UIApplication.didEnterBackgroundNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.logger.info("App backgrounded, clearing memory cache only")
        self?.memoryCache.removeAllObjects()
        // Keep disk cache and cancel in-flight requests
        self?.loadingTasks.values.forEach { $0.cancel() }
        self?.loadingTasks.removeAll()
      }
    }
  }

  func loadImage(from url: URL) async throws -> UIImage {
    // If already loading this URL, return the existing task
    if let existingTask = loadingTasks[url] {
      logger.debug("Reusing existing loading task for URL: \(url.absoluteString)")
      return try await existingTask.value
    }

    let task = Task<UIImage, Error> {
      let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)

      let (data, response) = try await imageSession.data(for: request)

      guard let image = UIImage(data: data) else {
        logger.error("Failed to decode image data for URL: \(url.absoluteString)")
        throw URLError(.cannotDecodeContentData)
      }

      // Cache the response
      if let httpResponse = response as? HTTPURLResponse {
        let cachedResponse = CachedURLResponse(response: httpResponse, data: data)
        urlCache.storeCachedResponse(cachedResponse, for: request)
        logger.debug(
          "Cached response for URL: \(url.absoluteString), status: \(httpResponse.statusCode)")
      }

      // Store in memory cache with cost based on image size
      let cost = data.count
      memoryCache.setObject(image, forKey: url as NSURL, cost: cost)

      return image
    }

    loadingTasks[url] = task

    do {
      let image = try await task.value
      loadingTasks.removeValue(forKey: url)
      return image
    } catch {
      loadingTasks.removeValue(forKey: url)
      throw error
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    imageSession.invalidateAndCancel()
  }

  func clearCache() {
    let memoryCount = memoryCache.countLimit
    let diskUsage = urlCache.currentDiskUsage
    let activeTaskCount = loadingTasks.count

    logger.info(
      "Clearing image cache - Memory objects: \(memoryCount), Disk usage: \(diskUsage/1024/1024)MB, Active tasks: \(activeTaskCount)"
    )

    memoryCache.removeAllObjects()
    urlCache.removeAllCachedResponses()

    // Cancel all in-flight requests
    loadingTasks.values.forEach { $0.cancel() }
    loadingTasks.removeAll()

    logger.info("Image cache cleared successfully")
  }
}
