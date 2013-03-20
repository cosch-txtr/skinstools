
require 'net/http'
require 'date'
require 'pp'


@redirect_ips=
{ 
    "89.246.67.228" => "http://de.txtr.com/",
    "109.73.186.2" => "http://it.txtr.com/",
    "213.249.128.117" => "http://gb.txtr.com/",
    "199.193.115.145" => "http://us.txtr.com/"
}

@urls = 
[ 
  "http://de.txtr.com/catalog/category/cxbhw/Geisteswissenschaften/",
  "http://de.txtr.com/catalog/category/cxbhw/Geisteswissenschaften/?sort=price&lang=&invert=False&page=1&bookprice=None&slv=grid",
  "http://de.txtr.com/catalog/category/b8m9w/English%20Books/",
  "http://de.txtr.com/catalog/category/b8m9w/English%20Books/?sort=price&lang=&invert=False&page=1&bookprice=None&slv=grid"
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
      res = Net::HTTP.get_response(uri)                    

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
                                          
                                          
exitcode=0

puts "testing redirects"
@redirect_ips.each do |key, value|
  puts "  testing for: " + value
  r,t = test_redirect(key,value)
  puts "    #{t}"
  exitcode = 1 if r
end

  
puts "testing cache misses"
run=3
while run>0
  @urls.each do |url|
    puts " testing for: "+url
    r,t = test_caching(url)
    puts "   #{t}"
    exitcode = 1 if r
  end
  run -=1
end                    
                          
exit exitcode