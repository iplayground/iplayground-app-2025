import SwiftUI

package struct CachedAsyncImage<Content>: View where Content: View {
  private let url: URL?
  private let content: (AsyncImagePhase) -> Content
  @State private var image: UIImage?
  @State private var isLoading = false

  package init(
    url: URL?,
    @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
  ) {
    self.url = url
    self.content = content
  }

  package var body: some View {
    Group {
      if let image = image {
        content(.success(Image(uiImage: image)))
      } else if isLoading {
        content(.empty)
      } else if url != nil {
        content(.empty)
      } else {
        content(.failure(URLError(.badURL)))
      }
    }
    .task(id: url) {
      await loadImage()
    }
  }

  @MainActor
  private func loadImage() async {
    guard let url = url else {
      image = nil
      return
    }

    // Check if image is already cached
    if let cachedImage = await ImageCacheManager.shared.cachedImage(for: url) {
      image = cachedImage
      return
    }

    // Check if we're already loading this URL
    if isLoading {
      return
    }

    isLoading = true

    do {
      let loadedImage = try await ImageCacheManager.shared.loadImage(from: url)
      image = loadedImage
    } catch {
      // Keep existing image if load fails, don't show error state
    }

    isLoading = false
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
  private var loadingTasks: [URL: Task<UIImage, Error>] = [:]

  private init() {
    // Configure memory cache
    memoryCache.countLimit = 100
    memoryCache.totalCostLimit = 50 * 1024 * 1024  // 50MB

    // Configure URL cache for disk storage
    let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
      .appendingPathComponent("ImageCache")

    try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

    urlCache = URLCache(
      memoryCapacity: 10 * 1024 * 1024,  // 10MB memory
      diskCapacity: 100 * 1024 * 1024,  // 100MB disk
      directory: cacheDirectory
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

  func loadImage(from url: URL) async throws -> UIImage {
    // If already loading this URL, return the existing task
    if let existingTask = loadingTasks[url] {
      return try await existingTask.value
    }

    let task = Task<UIImage, Error> {
      let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)

      let (data, response) = try await URLSession.shared.data(for: request)

      guard let image = UIImage(data: data) else {
        throw URLError(.cannotDecodeContentData)
      }

      // Cache the response
      if let httpResponse = response as? HTTPURLResponse {
        let cachedResponse = CachedURLResponse(response: httpResponse, data: data)
        urlCache.storeCachedResponse(cachedResponse, for: request)
      }

      // Store in memory cache
      memoryCache.setObject(image, forKey: url as NSURL)

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

  func clearCache() {
    memoryCache.removeAllObjects()
    urlCache.removeAllCachedResponses()
  }
}

#Preview {
  CachedAsyncImage(url: URL(string: "https://example.com/image.jpg")) { phase in
    switch phase {
    case let .success(image):
      image
        .resizable()
        .aspectRatio(contentMode: .fit)
    case .failure:
      Image(systemName: "xmark.circle")
    case .empty:
      ProgressView()
    @unknown default:
      EmptyView()
    }
  }
}
