eav-test
========

MySQL EAV Datastructure


First, you need import the source.sql. Then, you need to set a recursion limit:
```MYSQL
SET max_sp_recursion_depth = 100;
```

Then you can store and fetch data by xml:
```MYSQL
SET @xmlData = '
	<e name="base">
		<e name="products">
			<e name="12736">
				<a type="str" name="name">Hello World</a>
				<a type="str" name="description">This is a test</a>
				<a type="dec" name="price">99.99</a>
				<a type="int" name="stock">100</a>
				<a type="date" name="start-date">2014-02-15 12:00:00</a>
			</e>
		</e>
		<a type="str" name="name">Test data-structure</a>
		<a type="str" name="description">This is my data based on a eav schema.</a>
	</e>';

CALL eav__entity__store_xml('some/path', @xmlData);

SELECT eav__entity__fetch_xml('some/path', null);
```
