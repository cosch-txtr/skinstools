require 'rubygems'
gem 'test-unit', '=2.5.4'
require 'test/unit'
require 'ci/reporter/rake/test_unit_loader.rb'
require './skins'

class TestSkins < Test::Unit::TestCase

  def setup
    @skins = Skins.new
    @res = nil
  end
  
  def continue_test
    begin
      yield
    rescue Test::Unit::AssertionFailedError => e
      self.send(:add_failure, e.message, e.backtrace)
      return false
    else
      return true
    end
  end
  
  def check_redirect( ip, location)
    uri = URI.parse( @skins.redirect_host )
    req = Net::HTTP::new(uri.host, uri.port)
    #req.set_debug_output($stdout)
    headers = { 'X-Forwarded-for' => ip }

    path = uri.path.empty? ? "/" : uri.path
    res = req.get(path,headers)
    @res = res
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

      return if !continue_test{ 
	assert_not_nil res.get_fields('X-Cache'), "no X-Cache Header for #{url}"
      }
      
      cache = res.get_fields('X-Cache')[0]
      
      if cache.start_with?("MISS:")
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

    continue_test{ 
      assert_nil res.get_fields('X-Cache'), "found X-Cache Header for #{url}" 
    }    
  end
  
  def test_prod_redirect
    @skins.redirects.each do |ip, location|
      check_redirect(ip,location)
    end
  end
  
  def test_prod_cache
    @skins.urls_cache.each do |url|
      check_cache(url)
    end
  end
  
  def test_prod_nocache
    @skins.urls_nocache.each do |url|
	check_nocache( url )
    end
    
  end
  
  def test_stg_redirect
    @skins.staging!
    test_prod_redirect
  end
  
  def test_stg_cache
    @skins.staging!
    test_prod_cache
  end
  
  def test_stg_nocache
    @skins.staging!
    test_prod_nocache
  end
  
end