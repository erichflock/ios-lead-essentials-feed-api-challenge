//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient
	
	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}
		
	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}
	
	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
        
        client.get(from: url, completion: { [weak self] result in
            
            guard self != nil else { return }
            
            switch result {
            case .failure:
                completion(.failure(Error.connectivity))
            case let .success((data, httpResponse)):
                
                guard self?.isValidJson(data: data) == true, httpResponse.statusCode == 200 else {
                    completion(.failure(Error.invalidData))
                    return
                }
                
                ItemsMapper().mapJsonResponse(jsonResponse: data, completion: { feedImages in
                    completion(.success(feedImages))
                })
            }
        })
    }
    
    private func isValidJson(data: Data) -> Bool {
        
        if let _ = try? JSONSerialization.jsonObject(with: data, options: []) {
            return true
        }
        
        return false
    }
        
}

class ItemsMapper {
    
    private struct Root: Decodable {
        
        let items: [Item]
        
        var feed: [FeedImage] {
            return items.map { $0.item }
        }
    }

    private struct Item: Decodable {
        
        let image_id: UUID
        let image_desc: String?
        let image_loc: String?
        let image_url: URL

        var item: FeedImage {
            return FeedImage(id: image_id, description: image_desc, location: image_loc, url: image_url)
        }
    }
    
    func mapJsonResponse(jsonResponse: Data, completion: @escaping ([FeedImage]) -> Void) {
        
        do {
            let root = try JSONDecoder().decode(ItemsMapper.Root.self, from: jsonResponse)
            completion(root.feed)
        } catch {
            completion([])
        }
        
    }
}
