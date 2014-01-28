eav-test
========

MySQL EAV Datastructure

```MYSQL
SET @xmlData = '
	<e name="shop">
		<e name="products">
			<e name="12736">
				<a type="str" name="name">Hello World</a>
				<a type="str" name="description">Dies ist ein Test</a>
				<a type="dec" name="price">99.99</a>
				<a type="int" name="stock">100</a>
			</e>
		</e>
		<a type="str" name="name">Mein Onlineshop</a>
		<a type="str" name="description">This is my online shop based on a eav data schema.</a>
	</e>';
	
CALL eav__entity__store_xml('some/path', @xmlData);

SELECT eav__entity__fetch_xml('some/path', null);
```
