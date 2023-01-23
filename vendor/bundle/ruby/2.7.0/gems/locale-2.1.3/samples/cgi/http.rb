#! /usr/bin/env ruby
=begin
  http.rb - An WebServer for hello locale sample.

  Copyright (C) 2005-2008 Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby.

  Original: Ruby-GetText-Package 1.92.0

  $Id$
=end

require 'webrick'
require 'cgi'
require 'rbconfig'

interpreter = File.join(Config::CONFIG['bindir'], Config::CONFIG['ruby_install_name']) +
 			       Config::CONFIG['EXEEXT']

srv = WEBrick::HTTPServer.new({:BindAddress => '127.0.0.1',
                               :Logger => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
			      # :CGIInterpreter => "ruby -d",
			       :Port => 10080})

['INT', 'TERM'].each { |signal|
   trap(signal){ srv.shutdown} 
}

srv.mount("/", WEBrick::HTTPServlet::FileHandler, File.expand_path('.'))

srv.mount_proc("/src/") do |req, res|
  res.header["Content-Type"] = "text/html; charset=UTF-8"
  if req.query_string
    file = File.open(req.query_string).read
    res.body = %Q[<html>
                <head>
                  <title>View a source code</title>
                  <meta http-equiv="content-type" content="text/html; charset=UTF-8">
                  <link rel="stylesheet" type="text/css" href="/gettext.css" media="all">
                </head>
                <body><h1>#{req.query_string}</h1>
                <pre>#{CGI.escapeHTML(file)}</pre>
                <p><a href="/">Back</a></p>
                </body>
                </html>
                ]
  end
end

srv.start
