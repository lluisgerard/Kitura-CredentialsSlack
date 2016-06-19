# Kitura-CredentialsSlack
A plugin for the Credentials framework that authenticates using Slack.

![Mac OS X](https://img.shields.io/badge/os-Mac%20OS%20X-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
![Apache 2](https://img.shields.io/badge/license-Apache2-blue.svg?style=flat)

## Summary
A very rough plugin for [Kitura-Credentials](https://github.com/IBM-Swift/Kitura-Credentials) framework that authenticates using the [Sign in with Slack button](https://api.slack.com/docs/sign-in-with-slack). I adapted the code from [Kitura-CredentialsFacebook](https://github.com/IBM-Swift/Kitura-CredentialsFacebook).

## Table of Contents
* [Swift version](#swift-version)
* [Example](#example)
* [License](#license)

## Swift version
The latest version of Kitura-CredentialsSlack works with the DEVELOPMENT-SNAPSHOT-2016-05-03-a version of the Swift binaries. You can download this version of the Swift binaries by following this [link](https://swift.org/download/). Compatibility with other Swift versions is not guaranteed.

## Example
A complete sample for other credentials can be found in [Kitura-Credentials-Sample](https://github.com/IBM-Swift/Kitura-Credentials-Sample). I plan to add the Slack example but I totally recommend trying to build and play with that project first before using this module.
<br>

First create an instance of `CredentialsSlack` plugin and register it with `Credentials` framework:
```swift
import Credentials
import CredentialsSlack

let credentials = Credentials()
let slackCredentials = CredentialsSlack(clientId: slackClientId, clientSecret: slackClientSecret, callbackUrl: slackCallbackUrl)
credentials.register(plugin: slackCredentials)
```
**Where:**
   - *slackClientId* is the App ID of your Slack app
   - *slackClientSecret* is the App Secret of your Slack app

**Note:** The *callbackUrl* parameter above is used to tell the Slack web login page where the user's browser should be redirected when the login is successful. It should be a URL handled by the server you are writing.

Connect `credentials` middleware to requests to `/private`:

```swift
router.all("/private", middleware: credentials)
router.get("/private/data", handler:
    { request, response, next in
        ...  
        next()
})
```

And call `authenticate` to login with Slack and to handle the redirect (callback) from the Slack login web page after a successful login:

```swift
// SLACK
router.get("/login/slack",
           handler: credentials.authenticate(credentialsType: slackCredentials.name))
router.get("/login/slack/callback",
           handler: credentials.authenticate(credentialsType: slackCredentials.name, failureRedirect: "/login"))
```

## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE.txt).
