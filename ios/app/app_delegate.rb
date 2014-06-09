class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    $window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    $window.makeKeyAndVisible

    $web = UIWebView.alloc.initWithFrame(UIScreen.mainScreen.bounds)

    $window.addSubview($web)
    true
  end
end
