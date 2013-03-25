
require 'net/http'
require 'date'
require 'pp'
require 'openssl'

class Skins

  def initialize(*args)
    @redirect_host = "http://txtr.com"
    
    @redirect_ips=
    { 
	"89.246.67.228" => "http://de.txtr.com/",
	"109.73.186.2" => "http://it.txtr.com/",
	"213.249.128.117" => "http://gb.txtr.com/",
	"199.193.115.145" => "http://us.txtr.com/",
#	"192.189.54.23" => "http://au.txtr.com/",
	"194.208.32.23" => "http://at.txtr.com/",
	"46.253.160.23" => "http://be.txtr.com/",
#	"24.38.144.23" => "http://ca.txtr.com/",
	"78.153.191.23" => "http://dk.txtr.com/",
	"62.201.128.23" => "http://fr.txtr.com/",
	"82.141.192.23" => "http://ie.txtr.com/",
	"62.133.192.23" => "http://nl.txtr.com/",
	"62.181.160.23" => "http://pl.txtr.com/",
	"196.29.240.23" => "http://za.txtr.com/",
	"80.73.144.23" => "http://es.txtr.com/",
	"80.75.112.23" => "http://ch.txtr.com/"#,
	#"198.246.229.23" => "int.txtr.com" #is from barbados
    }
    
    @urls_cache = 
    [ 
      "http://de.txtr.com",
      "http://de.txtr.com/catalog/category/cxbhw/Geisteswissenschaften/",
      "http://de.txtr.com/catalog/category/cxbhw/Geisteswissenschaften/?sort=price&lang=&invert=False&page=1&bookprice=None&slv=grid",
      "http://de.txtr.com/catalog/category/b8m9w/English%20Books/",
      "http://de.txtr.com/catalog/category/b8m9w/English%20Books/?sort=price&lang=&invert=False&page=1&bookprice=None&slv=grid",
      "http://de.txtr.com/catalog/category/b8a9w/Kunst/",
      "http://de.txtr.com/catalog/document/f5fxag9/Vademecum-Autor%20unbekannt/",
      "http://gb.txtr.com",
      "http://gb.txtr.com/catalog/category/xe81w/Computing%20&%20information%20technology/",
      "http://gb.txtr.com/catalog/category/xe81w/Computing%20&%20information%20technology/?sort=price&lang=&invert=False&page=1&bookprice=None&slv=grid",
      "http://gb.txtr.com/catalog/category/xkasw/Earth%20sciences,%20geography,%20environment,%20planning/",
      "http://gb.txtr.com/catalog/document/a5ke8z9/Rambunctious%20Garden-Marris,%20Emma/"
    ]

    @urls_nocache =
    [
      "http://txtr.de",
      "http://txtr.com",
      "http://de.txtr.com/basket/",
      "http://gb.txtr.com/basket/"
    ]
    
    @missed = {}
    
    @staging = false
    
    @ssl = false
  end
  
  
  def redirect_host
    @redirect_host
  end
  
  
  def redirects
    @redirect_ips
  end

  
  def urls_cache
    @urls_cache
  end
  
  
  def urls_nocache
    @urls_nocache
  end
  
  
  def staging?
    @staging
  end
  
  
  def staging!
    @redirect_host = @redirect_host.gsub "txtr.com","staging.txtr.com"
    @redirect_ips.each do |ip, location|
	@redirect_ips[ip]=location.gsub "txtr.com","staging.txtr.com"
    end
    
    @urls_cache.each_with_index do | url,i |
      @urls_cache[i]=url.gsub "txtr.com","staging.txtr.com"
    end
    
    @urls_nocache.each_with_index do | url,i |
      @urls_nocache[i]=url.gsub "txtr.com","staging.txtr.com"
    end
    
    @staging = true
  end  
  
  
  def ssl?
    @ssl
  end
  
  def ssl!
    #due to nginx ssl proxy limits we still connect to http and set X-Forwarded-proto to https
    # so no https for redirect host anymore
    #@redirect_host = @redirect_host.gsub "http","https"
    @redirect_ips.each do |ip, location|
	@redirect_ips[ip]=location.gsub "http","https"
    end
    
    @urls_cache.each_with_index do | url,i |
      @urls_cache[i]=url.gsub "http","https"
    end
    
    @urls_nocache.each_with_index do | url,i |
      @urls_nocache[i]=url.gsub "http","https"
    end
    
    @ssl = true
  end
  
end
