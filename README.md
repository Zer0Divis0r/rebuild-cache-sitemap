# GitHub action to rebuild CDN cache using sitemaps

This action will go over sitemaps of a site and request each URL mentioned in them.   
Used for rebuilding website cache on a CDN. 

The action will find any referenced sitemaps on the first level of hierarchy.  
Meaning, if the root sitemap contains other references to XML files, it will process them as well, but not if referenced sitemaps contain more references.

## Usage
You have to provide one of: `sitemap_url` or `robots_domain_prefix` 

Using URL of a root sitemap:
```
name: Rebuild cache
uses: Zer0Divis0r/rebuild-cache-sitemap@v2
with:
  sitemap_url: 'https://example.com/sitemap_index.xml'
```

Using address of a site and it's robots.txt file:  
*Note: do not add slash in the end*
```
name: Rebuild cache
uses: Zer0Divis0r/rebuild-cache-sitemap@v2
with:
  robots_url_prefix: 'https://example.com'
```



## Inputs

## `robots_url_prefix`
Protocol + domain of a site where to grab robots.txt and find references to sitemaps.

## `sitemap_url`
Full URL of a sitemap to begin with.

## `use_wget`
Use wget instead of cURL. Wget would also make a request to all JS, CSS and image files referenced on the page

## `rate_limitation`
Rate limitation of requests per second. Default is 4 requests per second.

## Outputs

## `sitemapscount`
The number of sitemap files processed

## `urlscount`
Number of URLs grabbed (it may include some referenced sitemaps)
