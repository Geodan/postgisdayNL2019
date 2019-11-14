# postgisdayNL2019
Some code examples for postgisdayNL2019

```
CREATE TABLE radardata (
x UInt16, 
y UInt16, 
p UInt16, 
timestamp DateTime
) 
ENGINE = MergeTree 
PARTITION BY toDate(timestamp) 
ORDER BY (x, y);

```
