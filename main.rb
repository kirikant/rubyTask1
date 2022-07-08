require 'open-uri'
require 'csv'
require 'nokogiri/class_resolver'
require 'nokogiri'

def get_href_title(products)

  package_refs = []

  titles_hash = Hash.new
  image_refs_hash = Hash.new

  products_info = products.xpath('//a[@class=
"product_img_link pro_img_hover_scale product-list-category-img"]')

  puts"getting links of products packages"
  products_info.xpath('@href').each {
    |href|
    package_refs << href
  }

  puts"getting titles of products"
  products_info.xpath('@title').each_with_index {
    |title, i|
    titles_hash[String.new(package_refs[i])] = String.new(title)
  }

  puts"getting images of products"
  products_info.xpath('//img[@class="replace-2x img-responsive front-image"]//@src').each_with_index {
    |image_ref, i|
    image_refs_hash[String.new(package_refs[i])] = String.new(image_ref)
  }

  [titles_hash, image_refs_hash, package_refs]
end


def get_packages_prices(products_hash)
  puts"getting prices of products"
  ref_packages = Hash.new
  products_hash[2].each { |ref|
    html = URI.open(ref)
    product_page = Nokogiri::HTML(html)
    html.close


    (product_page.xpath('//div[@class="main_content_area"]
//div[@class="columns-container wide_container"]
')).each { |packages|

      package_types = []
      package_prices = []

      packages.xpath('//span[@class="radio_label"]').each { |package|
        package_types << String.new(package)
      }
      packages.xpath('//span[@class="price_comb"]').each { |price|
        package_prices << String.new(price)
      }

      package_types.each_with_index { |package, i|
        ref_packages["#{package},#{package_prices[i]}"] = String.new(ref)
      }
    }
  }
  ref_packages
end


def combine_info(products_hash, products_packages, file_name)
  doc = CSV.open("#{file_name}.env", "a+")
  image_refs = products_hash[1]
  titles = products_hash[0]

  puts "writing the data"
  doc << ["title", "price", "image_link"]
  products_packages.each { |key, value|
    array_csv = []
    array_csv << "#{titles[value]}(#{key.split(',')[0]})"
    array_csv << key.split(',')[1]
    array_csv << image_refs[value]

    doc << array_csv
  }

  doc.close

  puts "complete"
end

puts "enter the category link,please"
# url = 'https://www.petsonic.com/farmacia-para-gatos/?categorias=hepaticos,vitaminas-para-gatos'
url=gets()

puts "enter the file name,please"
file_name=gets()

html = URI.open(url)
category_page = Nokogiri::HTML(html)
html.close

products = category_page.xpath('//div[@class="main_content_area"]//div[@class="columns-container wide_container"]
//div[@class="pro_outer_box"]')

products_hash = get_href_title(products)
products_packages = get_packages_prices(products_hash)
combine_info(products_hash, products_packages, "#{file_name}")



