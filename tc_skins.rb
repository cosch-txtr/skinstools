require 'rubygems'
gem 'test-unit', '=2.5.4'
require 'test/unit'
require 'ci/reporter/rake/test_unit_loader.rb'
require './skins'

class TestSkins < Test::Unit::TestCase

  
  def setup
    @skins = Skins.new
    @res = nil
    @url = nil
  end
  
  
  def continue_test
    begin
      yield
    rescue Test::Unit::AssertionFailedError => e
      msg = e.message
      if( @url )
	msg += "\n"
	msg += ">>>>>>>> URL WAS >>>>>>>>>:\n#{@url}"
      end
      if( @res )
	msg += "\n"
	msg += ">>>> RESPONSE HEADERS >>>>:\n#{@res.to_hash.inspect.gsub ", ",", \n"}"
      end
      self.send(:add_failure, msg, e.backtrace)
      return false
    else
      return true
    end
  end
  
  
  def check_redirect( ip, location)
    uri = URI.parse( @skins.redirect_host )
    req = Net::HTTP::new(uri.host, uri.port)
    
    if (uri.class == URI::HTTPS )
      req.use_ssl = true
      req.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    
    #req.set_debug_output($stdout)
    headers = { 'X-Forwarded-for' => ip }
    headers['X-Forwarded-proto']="https" if @skins.ssl?

    path = uri.path.empty? ? "/" : uri.path
    res = req.get(path,headers)
    @res=res
    @url=@skins.redirect_host
    
    return if !continue_test{ 
	assert_equal "302", res.code, "wrong response code:#{res.code} for #{ip}:#{location}"
    }
    continue_test{ 
      assert_equal 1, res.get_fields('location').count, "wrong location count for #{ip}:#{location}"
    }
    continue_test{ 
      assert_equal location, res.get_fields('location')[0], "wrong location! for #{ip}:#{location}"
    }
  end
  
  
  def check_cache(url)
    uri = URI(url)
    
    i=2
    while i>0
      http = Net::HTTP.new( uri.host, uri.port )  
      if (uri.class == URI::HTTPS )
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      res = http.get("/")                    
      @res=res
      @url=url
      
      return if !continue_test{ 
	assert_not_nil res.get_fields('X-Cache'), "no X-Cache Header for #{url}"
      }
      
      cache = res.get_fields('X-Cache')[0]
      
      if cache.start_with?("MISS:")
	  return if !continue_test{ 
	    assert_not_nil @missed, "@missed[] is nil - internal test error"
	  }
	  continue_test{ 
	    assert_nil @missed[url], "missed more then once: #{url}"
	  }
	  @missed[url]=DateTime.now.strftime 
      end
      
      sleep(1)
      i -=1
    end
  end
  
  
  def check_nocache( url )
    uri = URI(url)
      
    http = Net::HTTP.new( uri.host, uri.port )  
    #http.set_debug_output($stdout)
    if (uri.class == URI::HTTPS )
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    
    path = uri.path.empty? ? "/" : uri.path
    res = http.get(path)                        
    @res=res
    @url=url
    
    cache = res.get_fields('X-Cache') == nil ? nil : res.get_fields('X-Cache')[0]
    
    if( cache )
      continue_test{ 
	assert_true cache.start_with?("MISS:"), "no X-Cache: MISS Header found for #{url}" 
      }

      continue_test{ 
	assert_false cache.start_with?("HIT:"), "found X-Cache: HIT Header for #{url}" 
      }
    end
  end
  
  
# http prod  
  def test_http_prod_redirect
    @skins.redirects.each do |ip, location|
      check_redirect(ip,location)
    end
  end
    
  def test_http_prod_cache
    @skins.urls_cache.each do |url|
      check_cache(url)
    end
  end
    
  def test_http_prod_nocache
    @skins.urls_nocache.each do |url|
	check_nocache( url )
    end  
  end  

  
# https prod  
  def test_https_prod_redirect
    @skins.ssl!
    test_http_prod_redirect
  end
  
  def test_https_prod_cache
    @skins.ssl!
    test_http_prod_cache
  end
  
  def test_https_prod_nocache
    @skins.ssl!
    test_http_prod_nocache
  end
  
  
# http stg  
  def test_http_stg_redirect_http
    @skins.staging!
    test_http_prod_redirect
  end
    
  def test_http_stg_cache
    @skins.staging!
    test_http_prod_cache
  end
  
  def test_http_stg_nocache
    @skins.staging!
    test_http_prod_nocache
  end
  
  
# https stg    
  def test_https_stg_redirect
    @skins.staging!
    @skins.ssl!
    test_http_prod_redirect
  end

  def test_https_stg_cache
    @skins.staging!
    test_http_prod_cache
  end
  
  def test_https_stg_nocache
    @skins.staging!
    test_http_prod_nocache
  end
  
end