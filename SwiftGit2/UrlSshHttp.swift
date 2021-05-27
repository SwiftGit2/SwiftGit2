//
//  UrlSshHttp.swift
//  SwiftGit2-OSX
//
//  Created by loki on 27.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation

// https://github.com/ukushu/PushTest.git
// ssh://git@github.com:ukushu/PushTest.git
private func urlGetHttp(url: String) -> String {
    var url = url
    if url.contains("https://") {
        return url
    }
    
    //else this is ssh and need to make https
    
    if url.contains("@") {
        let tmp = url.split(separator: "@")
        if tmp.count == 2 { url = String(tmp[1]) }
    }
    
    url = url.replacingOccurrences(of: "ssh://", with: "")
        .replacingOccurrences(of: ":", with: "/")
    
    return "https://\(url)"
}

// https://github.com/ukushu/PushTest.git
// ssh://git@github.com:ukushu/PushTest.git
private func urlGetSsh(url: String) -> String {
    var newUrl = url
    
    if newUrl.contains("github") {
        if !newUrl.contains("ssh://") && newUrl.contains("git@") {
            newUrl = "ssh://\(url)"
        }
        else if newUrl.contains("ssh://") && !newUrl.contains("git@") {
            newUrl = url.replacingOccurrences(of: "ssh://", with: "ssh://git@")
        }
    }
    else{
        if !newUrl.contains("ssh://"){
            newUrl = "ssh://\(url)"
        }
    }
    
    return newUrl.replacingOccurrences(of: ":", with: "/")
}
