#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
require 'bundler'
Bundler.require
require 'yaml'
require 'json'

class G2 < Sinatra::Base
  configure do
    set YAML.load_file(File.expand_path('../settings.yml', __FILE__))
    set :client, Tumblr::Client.new({
      consumer_key: tumblr['consumer_key'],
      consumer_secret: tumblr['consumer_secret'],
      oauth_token: tumblr['oauth_token'],
      oauth_token_secret: tumblr['oauth_token_secret']
    })
  end

  helpers do
    def blog_hostname
      "#{settings.tumblr['blog_name']}.tumblr.com"
    end

    def blog_archive_url
      "http://#{blog_hostname}/archive"
    end

    def blog_mega_editor_url
      "https://www.tumblr.com/mega-editor/#{settings.tumblr['blog_name']}"
    end

    def extract_mime_type(file)
      MIME::Types[file[:type] || 'image/png'].first
    end

    def extract_io(file, mime_type)
      Faraday::UploadIO.new(file[:tempfile].path, mime_type.content_type)
    end

    def upload(data)
      options = {data: data}
      options[:state] = 'private' if settings.tumblr['private']
      result = settings.client.photo(blog_hostname, options)
      settings.client.posts blog_hostname, id: result['id']
    end

    def boolean(value)
      %w(1 true t yes y).include? value.to_s.downcase
    end

    def shorten_url(url)
      conn = Faraday.new 'https://api-ssl.bitly.com' do |conn|
        conn.request :url_encoded
        conn.response :follow_redirects
        conn.response :json, content_type: /\bjson$/
        conn.adapter Faraday.default_adapter
      end

      res = conn.get '/v3/user/link_save' do |req|
        req.params = {
          access_token: settings.bitly['access_token'],
          longUrl: url,
          private: settings.bitly['private']
        }
      end

      res.body['data']['link_save']['link']
    end

    def format_url(url, mime_type)
      url = shorten_url(url) if boolean(params.fetch(:shorten, settings.app['shorten_url']))
      url = "#{url}#.#{mime_type.extensions.last}" if boolean(params.fetch(:hash, settings.app['format_hash']))
      url
    end

    def gist(filename, content, options = {})
      data = {
        description: options[:description],
        public: options.fetch(:public, false),
        files: {
          filename => {
            content: content
          }
        }
      }

      conn = Faraday.new 'https://api.github.com' do |conn|
        conn.request :json
        conn.response :follow_redirects
        conn.response :json, content_type: /\bjson$/
        conn.adapter Faraday.default_adapter
      end

      res = conn.post '/gists', data
      res.body['html_url']
    end

    def json(data)
      content_type 'application/json'
      body JSON.dump(data)
    end
  end

  post '/webupload' do
    files = (params[:files] || []).map do |file|
      mime_type = extract_mime_type file
      res = upload extract_io(file, mime_type)
      photo = res['posts'][0]['photos'][0]
      original = photo['original_size']
      thumbnail = photo['alt_sizes'].find { |s| s['width'] < 400 }

      {
        name: file[:filename],
        size: file[:tempfile].size,
        url: format_url(original['url'], mime_type),
        thumbnailUrl: thumbnail['url'],
      }
    end
    json({files: files})
  end

  get '/' do
    erb :index
  end

  post %r(/|/upload(\.cgi)?) do
    begin
      file = params[:imagedata]
      mime_type = extract_mime_type file
      res = upload extract_io(file, mime_type)
      format_url res['posts'][0]['photos'][0]['original_size']['url'], mime_type
    rescue => e
      errors = ["#{e.class} - #{e.to_s}:"] + e.backtrace.map { |s| "\t#{s}" }
      url = gist 'error.txt', errors.join("\n")
      "#{url}#.png"
    end
  end
end
