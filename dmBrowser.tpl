<html>
<head>
<title>HFS %folder%</title>
</head><body>
%up%
%files%
</body>
</html>

[up]
<a class=folder href="%parent-folder%">UP</a>

[nofiles]
<div class=folder>No files</div>

[files]
%list%

[file]
<a href="%item-url%">%item-name%</a>

[folder]
<a href="%item-url%">%item-name%</a>

[comment]
<div class=comment>%item-comment%</div>

[error-page]
<html><head></head><body>
%content%
</body>
</html>

[not found]
<h1>404 -  Not found</h1>
<a href='/'>go to root</a>

[overload]
<h1>Server busy</h1>
Please, retry later.
