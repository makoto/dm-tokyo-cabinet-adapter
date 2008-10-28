require 'tokyocabinet'
include TokyoCabinet

`rm data/*db`
data = "data/"

User = Struct.new(:name, :age)
tom = [1, User.new('Tom', 33)]
peter = [2, User.new('Peter', 34)]

Post = Struct.new(:title, :user_id)
post1 = [3, Post.new('Good Morning', tom[0])] 
post2 = [4, Post.new('Good Evening', peter[0])] 
post3 = [5, Post.new('Good Night', peter[0])] 

#Item.fdb
# FDB for primary key of each item.
item = FDB::new
item.open(data + "Item.fdb", FDB::OWRITER | FDB::OCREAT)

item.put(tom[0], Marshal.dump(tom[1]))
item.put(peter[0], Marshal.dump(peter[1]))

item.put(post1[0], Marshal.dump(post1[1]))
item.put(post2[0], Marshal.dump(post2[1]))
item.put(post3[0], Marshal.dump(post3[1]))

p "All items."
item.each{|e| p e}

name_attr = HDB::new
name_attr.open(data + "NameAttr.hdb", HDB::OWRITER | HDB::OCREAT)
name_attr.put(tom[1][:name], tom[0])
name_attr.put(peter[1][:name], peter[0])

p "All name attributes"
name_attr.each{|e| p e}


age_attr = BDB::new
age_attr.open(data + "AgeAttr.bdb", BDB::OWRITER | BDB::OCREAT)
age_attr.put(tom[1][:age], tom[0])
age_attr.put(peter[1][:age], peter[0])

p "All age attributes"
age_attr.each{|e| p e}


p "User.first(:name => \"Tom\")"
p Marshal.load(item.get(name_attr.get("Tom")))
# => #<struct User name="Tom", age=33>

p "User.all(:age.gt => 33)"
ages = age_attr.range(33,true)
p ages.collect{|age|
 Marshal.load(item.get(age_attr.get(age)))
}
# => [#<struct User name="Tom", age=33>, #<struct User name="Peter", age=34>]

#TitleAttr.hdb
# HDB if it's unique

title_attr = HDB::new
title_attr.open(data + "TitleAttr.hdb", HDB::OWRITER | HDB::OCREAT)
title_attr.put(post1[1][:title], post1[0])
title_attr.put(post2[1][:title], post2[0])
title_attr.put(post3[1][:title], post3[0])

p "All title attributes"
title_attr.each{|e| p e}


#UserIDAttr.bdb 
# foreign_key is BDB to allow duplicate ids
user_id_attr = BDB::new
user_id_attr.open(data + "UserIDAttr.bdb", BDB::OWRITER | BDB::OCREAT)
user_id_attr.putlist(post1[1][:user_id], [post1[0]])
user_id_attr.putlist(post2[1][:user_id], [post2[0]])
user_id_attr.putlist(post3[1][:user_id], [post3[0]])

p "All user id attributes"
user_id_attr.each{|e| p e}


p  "post1.user"
p Marshal.load(item.get(Marshal.load(item.get(title_attr.get("Good Evening"))).user_id))
#=> #<struct User name="Peter", age=34>

p  "peter.posts"
p user_id_attr.getlist(name_attr.get("Peter")).collect{|post|
  Marshal.load(item.get(post))
}
#=> [#<struct Post title="Good Evening", user_id=2>, #<struct Post title="Good Night", user_id=2>]

item.close
name_attr.close
age_attr.close
title_attr.close
user_id_attr.close