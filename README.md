eav-test
========

MySQL EAV Datastructure

```MYSQL
SET @xmlData = '
	<e name="base">
		<e name="products">
			<e name="12736">
				<a type="str" name="name">Hello World</a>
				<a type="str" name="description">This is a test</a>
				<a type="dec" name="price">99.99</a>
				<a type="int" name="stock">100</a>
			</e>
		</e>
		<a type="str" name="name">Test data-structure</a>
		<a type="str" name="description">This is my data based on a eav schema.</a>
	</e>';
	
CALL eav__entity__store_xml('some/path', @xmlData);

SELECT eav__entity__fetch_xml('some/path', null);
```
