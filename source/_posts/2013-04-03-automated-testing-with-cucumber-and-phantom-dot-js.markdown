---
layout: post
title: "Automated testing with Cucumber and Phantom.js"
date: 2013-04-03 08:39
comments: true
categories: 
---
Since I last spoke to you, I've been very busy. I've recently changed jobs and am now working at the [Open Data Institute](http://theodi.org). It's a massive change from working at my old place, and one of the many new things I've learnt about is the joys of automated testing.

Working, as I did, on my own, in isolation (almost as a one man [skunkworks](http://blog.pezholio.co.uk/2012/09/local-gds-a-skunkworks-for-local-government/)) meant I didn't really need to worry about the quality of my code, and, as far as testing went - I could just test it in my browser and it'd work, right?

Well, yeah, I suppose, but this isn't The Right Way of doing things. Also, if I changed a line of code, how could I be sure that what I changed wouldn't have unintended consequences in some obscure part of my application without testing the whole application myself? Also, as I would often not have a development environment (at least in my non-Ruby apps), this would mean introducing a whole load of test data into my live environment.

In short, writing code without tests is a Very Bad Idea, and, as we move to the holy grail of [continuous deployment](http://en.wikipedia.org/wiki/Continuous_delivery) at the ODI, this would mean that my code will be getting pushed into the live environment regularly by [robots](http://jenkins.theodi.org/), so we need to make sure that any changes made aren't going to break anything. 

This is where [Cucumber](http://cukes.info) comes in. I won't go into this too much, but this is where the magic happens. I can write expectations (in a language called [Gherkin](https://github.com/cucumber/cucumber/wiki/Gherkin)), and write code in Ruby that attempts to match these expectations. I can call code that queries the database, spins up browsers and acts like a real user and [records HTTP interactions](https://github.com/vcr/vcr).

This is all well and good, but if I'm building an app that makes heavy use of JavaScript, then, out of the box, Cucumber (via [Selinium](http://docs.seleniumhq.org/)) needs to spin up a real browser (such as Firefox or Chrome). This is OK when developing on my Mac at work, but once the code is being tested remotely in Jenkins before deploy, this isn't possible.

However, there does exist a neat tool called [Phantom.js](http://phantomjs.org/) - a fully functional WebKit browser (like Chrome), but without one crucial thing, a window. All user interactions are carried out via JavaScript, and you can do everything a normal user would do, but without having to have a GUI. This mean you can automate all sorts of tasks on the command line, screen scraping, filling out forms, and yes, testing.

As Phantom.js is not like other browsers, getting Phantom.js and Cucumber to play nicely together is not, a straightforward task. However, there is a nice tool called [Poltergeist](https://github.com/jonleighton/poltergeist), which allows you to do just that. 

Getting Poltergeist set up in a Rails app is easy, but not trivial, and I had to jump through a few hoops to get it sorted, so I thought I'd document it here for the ages.

I'm assuming you've got `Cucumber-rails` set up in your Rails app already, so if you haven't, take a look at this [Railscast](http://railscasts.com/episodes/155-beginning-with-cucumber) to get you started.

Once you're all set up, the first thing to do is install Phantom.js - if you're on a Mac and running Homebrew, it's as easy as running `brew install phantomjs` on the command line, otherwise [take a look at these instructions](http://phantomjs.org/download.html).

Next, add `poltergeist` to your `gemfile` (probably in your `:test` group) like so:

	gem 'poltergeist'
	
and run `bundle install`

The next thing to do is register Poltergeist as a new browser in Cucumber, and make it run as the default driver for all your JavaScript tests. Open up your `features/support/env.rb` file and add the following lines:

	require 'capybara/poltergeist'
	
	Capybara.register_driver :poltergeist do |app|
  		Capybara::Poltergeist::Driver.new(app, {debug: false})
	end

	Capybara.javascript_driver = :poltergeist
	
Then you should be good to go! Crucially, you need to make sure you add the `@javascript` tag to all your tests, so Capybara knows to use Poltergeist for your tests, but other than that, when you now run your tests, rather than a browser window being fired up, everything happens in the background like magic!

There are a couple of other cool things you can do with Poltergeist that may help you when you're writing initial tests, like taking screenshots and executing arbitrary JavaScript (like in the JS Console in Chrome). [Take a look at the docs](https://github.com/jonleighton/poltergeist#whats-supported) for more info, and have fun!

One very small gotcha, is that, as Capybara fires up a real browser when running tests, if you're recording API interactions with [VCR](https://github.com/vcr/vcr), it will try and record your browser interactions too. To get around this, you'll need to make VCR ignore local requests by adding this line to your `features/support/vcr.rb` file:

	VCR.configure do |c|
		c.ignore_localhost = true
	end
