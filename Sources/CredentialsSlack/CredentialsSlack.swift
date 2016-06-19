//
//  CredentialsSlack.swift
//  KituraCredentialsSlack
//
//  Created by Lluis Gerard on 19/06/2016.
//
//

import Kitura
import KituraNet
import LoggerAPI
import Credentials

import SwiftyJSON

import Foundation

public class CredentialsSlack : CredentialsPluginProtocol {
  
  private var clientId : String
  
  private var clientSecret : String
  
  public var callbackUrl : String
  
  public var name : String {
    return "Slack"
  }
  
  public var redirecting : Bool {
    return true
  }
  
  public init (clientId: String, clientSecret : String, callbackUrl : String) {
    self.clientId = clientId
    self.clientSecret = clientSecret
    self.callbackUrl = callbackUrl
  }
  
  #if os(OSX)
  public var usersCache : NSCache<NSString, BaseCacheElement>?
  #else
  public var usersCache : NSCache?
  #endif
  
  private let hostname = "slack.com"
  
  /// https://api.slack.com/docs/sign-in-with-slack
  public func authenticate (request: RouterRequest, response: RouterResponse, options: [String:OptionValue], onSuccess: (UserProfile) -> Void, onFailure: (HTTPStatusCode?, [String:String]?) -> Void, onPass: (HTTPStatusCode?, [String:String]?) -> Void, inProgress: () -> Void) {
    if let code = request.queryParams["code"] {
        
      var requestOptions = [ClientRequestOptions]()
      requestOptions.append(.schema("https://"))
      
      requestOptions.append(.hostname(self.hostname))
      requestOptions.append(.method("GET"))
      requestOptions.append(.path("/api/oauth.access?client_id=\(clientId)&client_secret=\(clientSecret)&code=\(code)"))
      var headers = [String:String]()
      headers["Accept"] = "application/json"
      requestOptions.append(.headers(headers))
    
      let requestForToken = HTTP.request(requestOptions) { response in
        if let response = response where response.statusCode == HTTPStatusCode.OK {
          do {
            var body = NSMutableData()
            try response.readAllData(into: body)
            var jsonBody = JSON(data: body)

            if let token = jsonBody["access_token"].string {

              requestOptions = [ClientRequestOptions]()
              requestOptions.append(.schema("https://"))
              requestOptions.append(.hostname(self.hostname))
              requestOptions.append(.method("GET"))
              requestOptions.append(.path("/api/users.identity?token=\(token)"))
              headers = [String:String]()
              headers["Accept"] = "application/json"
              requestOptions.append(.headers(headers))

              let requestForProfile = HTTP.request(requestOptions) { profileResponse in
                if let profileResponse = profileResponse where profileResponse.statusCode == HTTPStatusCode.OK {
                  do {
                    body = NSMutableData()
                    try profileResponse.readAllData(into: body)
                    jsonBody = JSON(data: body)
                    
                    if let id = jsonBody["user"]["id"].string,
                      let name = jsonBody["user"]["name"].string {
                      let userProfile = UserProfile(id: id, displayName: name, provider: self.name)
                      onSuccess(userProfile)
                      return
                    }
                  }
                  catch {
                    Log.error("Failed to read \(self.name) response")
                  }
                }
                else {
                  onFailure(nil, nil)
                }
              }
              requestForProfile.end()
            }
          }
          catch {
            Log.error("Failed to read \(self.name) response")
          }
        }
        else {
          onFailure(nil, nil)
        }
      }
      requestForToken.end()
    }
    else {
      // Log in
      do {
        try response.redirect("https://slack.com/oauth/authorize?scope=identity.basic&client_id=\(clientId)")
        inProgress()
      }
      catch {
        Log.error("Failed to redirect to \(self.name) login page")
      }
    }
  }
}
