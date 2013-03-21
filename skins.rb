
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
	"199.193.115.145" => "http://us.txtr.com/"
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
      "http://txtr.com",
      "http://de.txtr.com/basket/",
      "http://gb.txtr.com/basket/",
      "https://de.txtr.com/basket/"
    ]
    
    @missed = {}
    
    @staging = false;
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
  end  
  
end
