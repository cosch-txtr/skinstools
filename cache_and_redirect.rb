
#
# this needs ruby 2.0.0
#

require 'net/http'
require 'date'
require 'pp'
require 'openssl'


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

def test_redirect( ip, location) 
    uri = URI.parse( "http://txtr.com" )
    req = Net::HTTP::new(uri.host, uri.port)
    
    headers = { 'X-Forwarded-for' => ip }

    path = uri.path.empty? ? "/" : uri.path
    res = req.get(path,headers)
    
    
    return false, "wrong response code:#{res.code}" if res.code!="302"
    return false, "wrong location count" if res.get_fields('location').count<1
    return false, "wrong location: #{res.get_fields('location')[0]} should be #{location}" if res.get_fields('location')[0]!=location
    
    return true, "ok"
end
    

@missed = {}


def test_caching(url) 
    uri = URI(url)
    
    i=2
    while i>0
      http = Net::HTTP.new( uri.host, uri.port )  
      if (uri.class == URI::HTTPS )
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      res = http.get("/")                    

      return false, "no X-Cache Header" if (res.get_fields('X-Cache')==nil)
      
      cache = res.get_fields('X-Cache')[0]
      
      if cache.start_with?("MISS:")
	  return false, "missed more then once: #{url}" if @missed[url]!=nil
	  @missed[url]=DateTime.now.strftime 
      end
      
      sleep(1)
      i -=1
    end
    
    return true, "ok"
end

def test_nocaching(url)
    uri = URI(url)
    
    http = Net::HTTP.new( uri.host, uri.port )  
    #http.set_debug_output($stdout)
    if (uri.class == URI::HTTPS )
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    
    path = uri.path.empty? ? "/" : uri.path
    res = http.get(path)                        

    return false, "found X-Cache Header" if (res.get_fields('X-Cache')!=nil)
    
    return true, "ok"
end                                          
                                          
exitcode=0

puts "testing redirects"
@redirect_ips.each do |key, value|
  puts "  testing for: " + value
  r,t = test_redirect(key,value)
  puts "    #{t}"
  exitcode = 1 if !r
end

  
puts "testing cache for unintended misses"
run=1
while run>0
  @urls_cache.each do |url|
    puts " testing for: "+url
    r,t = test_caching(url)
    puts "   #{t}"
    exitcode = 1 if !r
  end
  run -=1
end                    

puts "testing cache for unintended hits"
@urls_cache.each do |url|
  #@urls_nocache.push( url.gsub "http", "https" )
end

run=1
while run>0
  @urls_nocache.each do |url|
    puts " testing for: "+url
    r,t = test_nocaching(url)
    puts "   #{t}"
    exitcode = 1 if !r
    sleep(0.5)
  end
  run -=1
end        

exit exitcode