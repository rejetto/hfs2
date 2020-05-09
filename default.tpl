Welcome! This is the default template for HFS 2.4
template revision TR3.

Here below you'll find some options affecting the template.
Consider 1 is used for "yes", and 0 is used for "no".

DO NOT EDIT this template just to change options. It's a very bad way to do it, and you'll pay for it!
Correct way: in Virtual file system, right click on home/root, properties, diff template,
put this text [+special:strings]
and following all the options you want to change, using the same syntax you see here.

[+special:strings]

option.newfolder=1
option.move=1
option.comment=1
option.rename=1
COMMENT with these you can disable some features of the template. Please note this is not about user permissions, this is global!

[common-head]
<!DOCTYPE html>
<html>
<head>
	<meta http-equiv="content-type" content="text/html; charset=UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<link rel="shortcut icon" href="/favicon.ico">
	<link rel="stylesheet" href="/?mode=section&id=style.css" type="text/css">

[]
{.$common-head.}
	<title>{.!HFS.} %folder%</title>
    <script type="text/javascript" src="/?mode=jquery"></script>
	<style class='trash-me'>
	.onlyscript, button[onclick] { display:none; }
	</style>
    <script>
    // this object will store some %symbols% in the javascript space, so that libs can read them
    HFS = { folder:'{.js encode|%folder%.}' };
    </script>
	<script type="text/javascript" src="/?mode=section&id=lib.js"></script>
</head>
<body>
	<div id="wrapper">
	<!--{.comment|--><h1 style='margin-bottom:100em'>WARNING: this template is only to be used with HFS 2.3 (and macros enabled)</h1> <!--.} -->
	{.$menu panel.}
	{.$folder panel.}
	{.$list panel.}
	</div>
</body>
<!-- Build-time: %build-time% -->
</html>

[list panel]
{.if not| %number% |{:
	<div id='nothing'>{.!{.if|{.length|{.?search.}.}|No results|No files.}.}</div> 
:}|{:
	<div id='files' class="hideTs {.for each|z|mkdir|comment|move|rename|delete|{: {.if|{.can {.^z.}.}|can-{.^z.} .}:}.}">
	%list%
	</div>
:}.}
<div id="serverinfo">
	<a href="http://www.rejetto.com/hfs/"><i class="fa fa-coffee"></i> {.!Uptime.}: %uptime%</a>
</div>


[menu panel]
<script>
	$(function(){
        if ($('#menu-panel').css('position').indexOf('sticky') < 0) // sticky is not supported
            setInterval(function(){ $('#wrapper').css('margin-top', $('#menu-panel').height()+5) }, 300); // leave space for the fixed panel
    });

    function changePwd() {
        {.if|{.can change pwd.}
        | ask(this.innerHTML, 'password', function(s){
            s && ajax('changepwd', {'new':s}, getStdAjaxCB([
                "!{.!Password changed, you'll have to login again..}",
                '>~login'
            ]))
        })
        | showError("{.!Sorry, you lack permissions for this action.}")
		.}
    }//changePwd

    function ajax(method, data, cb) {
        if (!data)
            data = {};
        data.token = "{.cookie|HFS_SID_.}";
        return $.post("?mode=section&id=ajax."+method, data, cb||getStdAjaxCB());
    }//ajax

</script>

<div id='menu-panel'>
	<div id="title-bar">
		{.$title-bar.}
	</div>
	<div id="menu-bar">
		{.if| {.length|%user%.}
		| <button class='pure-button' onclick='$("#user-panel").toggle()'><i class='fa fa-user-circle'></i><span>%user%</span></button>
		| <button class='pure-button' title="{.!Login.}" onclick='location = "~login"'><i class='fa fa-user'></i><span>{.!Login.}</span></button>
		.}
		{.if| {.get|can recur.} |
		<button class='pure-button' onclick="{.if|{.length|{.?search.}.}| location = '.'| $('#search-panel').toggle().find(':input:first').focus().}">
			<i class='fa fa-search'></i><span>{.!Search.}</span>
		</button>
		/if.}
		<button id="multiselection" class='pure-button' title="{.!Enable multi-selection.}"  onclick='toggleSelection()'>
			<i class='fa fa-check-square'></i>
			<span>{.!Selection.}</span>
		</button>
		{.if|{.can mkdir.}|
			<button title="{.!New folder.}" class='pure-button' id='newfolderBtn' onclick='ask(this.innerHTML, "text", name=> ajax("mkdir", { name:name }))'>
				<i class="fa fa-folder"></i>
				<span>{.!New folder.}</span>
			</button>
		.}
		<button id="toggleTs" class='pure-button' title="{.!Display timestamps.}"  onclick="toggleTs()">
			<i class='fa fa-clock-o'></i>
			<span>{.!Toggle timestamp.}</span>
		</button>

		{.if|{.get|can archive.}|
		<button id='archiveBtn' class='pure-button' onclick='ask("{.!Download these files as a single archive?.}", function() { submit({ selection: getSelectedItemsName() }, "{.get|url|mode=archive|recursive.}") })'>
			<i class="fa fa-file-archive-o"></i>
			<span>{.!Archive.}</span>
		</button>
		.}
		{.if| {.get|can upload.} |{:
			<button id="upload" onclick="upload()" class='pure-button' title="{.!Upload.}">
				<i class='fa fa-upload'></i>
				<span>{.!Upload.}</span>
			</button>
		:}.}

		<button id="sort" onclick="changeSort()" class='pure-button'>
			<i class='fa fa-sort'></i>
			<span></span>
		</button>
	</div>

    <div id="additional-panels">
        <div id="user-panel" class="additional-panel" style="display:none;">
			<span>{.!User.}: %user%</span>
			<button class="pure-button" onclick='changePwd.call(this)'><i class="fa fa-key"></i> {.!Change password.}</button>
        </div>
		{.$search panel.}
		{.$upload panel.}
		<div id="selection-panel" class="additional-panel" style="display:none">
			<label><span id="selected-counter">0</span> {.!selected.}</label>
			<span class="buttons">
				<button id="select-mask" class="pure-button"><i class="fa fa-asterisk"></i><span>{.!Mask.}</span></button>
				<button id="select-invert" class="pure-button"><i class="fa fa-retweet"></i><span>{.!Invert.}</span></button>
				<button id="delete-selection" class="pure-button"><i class="fa fa-trash"></i><span>{.!Delete.}</span></button>
				<button id="move-selection" class="pure-button"><i class="fa fa-truck"></i><span>{.!Move.}</span></button>
			</span>
		</div>
    </div>
</div>

[title-bar]
<i class="fa fa-globe"></i> {.!title.}
<i class="fa fa-lightbulb" id="switch-theme"></i>
<script>
$('body').addClass(getCookie('theme'))
$(function(){

    var titleBar = $('#title-bar')
	var h = titleBar.height()
	var on = true
	var k = 'shrink'
    window.onscroll = function(){
        if (window.scrollY > h)
        	titleBar.addClass(k)
		else if (!window.scrollY)
            titleBar.removeClass(k)
    }

    $('#switch-theme').click(function(ev) {
        var k = 'dark-theme';
        $('body').toggleClass(k);
        setCookie('theme', $('body').hasClass(k) ? k : '');
    });
});
</script>
<style>
	#title-bar { color:white; height:1.5em; transition:height .2s ease; overflow:hidden; position: relative; top: 0.2em;font-size:120%; }
	#title-bar.shrink { height:0; }
	#foldercomment { clear:left; }
	#switch-theme { color: #aaa; position: absolute; right: .5em; }
</style>

[folder panel]
<div id='folder-path'>
	{.breadcrumbs|{:<a class='pure-button' href="%bread-url%"/> {.if|{.length|%bread-name%.}|/ %bread-name%|<i class='fa fa-home'></i>.}</a>:} .}
</div>
{.if|%number%|
<div id='folder-stats'>
	%number-folders% {.!folders.}, %number-files% {.!files.}, {.add bytes|%total-size%.}
</div>
.}
{.123 if 2| <div id='foldercomment' class="comment"><i class="fa fa-quote-left"></i>|{.commentNL|%folder-item-comment%.}|</div> .}

[upload panel]
<div id="upload-panel" class="additional-panel closeable" style="display:none">
	<div id="upload-counters">
		{.!Uploaded.}: <span id="upload-ok">0</span> - {.!Failed.}: <span id="upload-ko">0</span> - {.!Queued.}: <span id="upload-q">0</span>
	</div>
	<div id="upload-results"></div>
	<div id="upload-progress">
		{.!Uploading....} <span id="progress-text"></span>
		<progress max="1"></progress>
	</div>
	<button class="pure-button" onclick="reload()"><i class="fa fa-refresh"></i> {.!Reload page.}</button>
</div>

[search panel]
<div id="search-panel" class="additional-panel closeable" style="{.if not|{.length|{.?search.}.}|display:none.}">
	<form>
		{.!Search.} <input name="search" value="{.escape attr|{.?search.}.}" />
		<br><input type='radio' name='where' value='fromhere' checked='true' />  {.!this folder and sub-folders.}
		<br><input type='radio' name='where' value='here' />  {.!this folder only.}
		<br><input type='radio' name='where' value='anywhere' />  {.!entire server.}
		<button type="submit" class="pure-button">{.!Go.}</button>
	</form>
</div>
<style>
	#search-panel [name=search] { margin: 0 0 0.3em 0.1em; }
	#search-panel button { float:right }
</style>
<script>
    $('#search-panel').submit(function(){
        var s = $(this).find('[name=search]').val()
        var folder = ''
        var ps = []
        switch ($('[name=where]:checked').val()) {
            case 'anywhere': folder = '/'
            case 'fromhere':
                ps.push('search='+s)
                break
            case 'here':
                if (s.indexOf('*') < 0)
                    s = '*'+s+'*'
                ps.push('files-filter='+s)
                ps.push('folders-filter='+s)
                break
        }
        location = folder+'?'+ps.join('&')
        return false
    })
</script>

[+special:strings]
title=HTTP File Server
max s dl msg=There is a limit on the number of <b>simultaneous</b> downloads on this server.<br>This limit has been reached. Retry later.
retry later=Please, retry later.
item folder=in folder
no files=No files in this folder
no results=No items match your search query
confirm=Are you sure?

[icons.css|no log]
@font-face { font-family: 'fontello';
	src: url('data:application/x-font-woff;base64,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') format('woff');
}
.fa { font-family: "fontello"; font-style: normal; font-weight: normal; }
.fa-asterisk::before { content:"\e800" }
.fa-check-circled::before { content:"\e801" }
.fa-user::before { content:"\e802" }
.fa-clock-o::before { content:"\e803" }
.fa-download::before { content:"\e804" }
.fa-ban::before { content:"\e805" }
.fa-edit::before { content:"\e806" }
.fa-check-square::before { content:"\e807" }
.fa-folder::before { content:"\e808" }
.fa-globe::before { content:"\e809" }
.fa-home::before { content:"\e80a" }
.fa-key::before { content:"\e80b" }
.fa-lock::before { content:"\e80c" }
.fa-refresh::before { content:"\e80d" }
.fa-retweet::before { content:"\e80e" }
.fa-search::before { content:"\e80f" }
.fa-star::before { content:"\e810" }
.fa-cancel-circled::before { content:"\e811"; }
.fa-truck::before { content:"\e812" }
.fa-upload::before { content:"\e813" }
.fa-bars::before { content:"\f0c9" }
.fa-coffee::before { content:"\f0f4" }
.fa-quote-left::before { content:"\f10d" }
.fa-file-archive-o::before { content:"\f1c6" }
.fa-trash::before { content:"\f1f8" }
.fa-user-circle::before { content:"\f2bd" }
.fa-lightbulb:before { content: '\f0eb' }
.fa-sort:before { content: '\f0dc' }
.fa-sort-alt-up:before { content: '\f160' }
.fa-sort-alt-down:before { content: '\f161' }

[style.css|no log|cache]
/*! normalize.css v8.0.0 | MIT License | github.com/necolas/normalize.css */html{line-height:1.15;-webkit-text-size-adjust:100%}body{margin:0}h1{font-size:2em;margin:.67em 0}hr{box-sizing:content-box;height:0;overflow:visible}pre{font-family:monospace,monospace;font-size:1em}a{background-color:transparent}abbr[title]{border-bottom:none;text-decoration:underline;text-decoration:underline dotted}b,strong{font-weight:bolder}code,kbd,samp{font-family:monospace,monospace;font-size:1em}small{font-size:80%}sub,sup{font-size:75%;line-height:0;position:relative;vertical-align:baseline}sub{bottom:-.25em}sup{top:-.5em}img{border-style:none}button,input,optgroup,select,textarea{font-family:inherit;font-size:100%;line-height:1.15;margin:0}button,input{overflow:visible}button,select{text-transform:none}[type=button],[type=reset],[type=submit],button{-webkit-appearance:button}[type=button]::-moz-focus-inner,[type=reset]::-moz-focus-inner,[type=submit]::-moz-focus-inner,button::-moz-focus-inner{border-style:none;padding:0}[type=button]:-moz-focusring,[type=reset]:-moz-focusring,[type=submit]:-moz-focusring,button:-moz-focusring{outline:1px dotted ButtonText}fieldset{padding:.35em .75em .625em}legend{box-sizing:border-box;color:inherit;display:table;max-width:100%;padding:0;white-space:normal}progress{vertical-align:baseline}textarea{overflow:auto}[type=checkbox],[type=radio]{box-sizing:border-box;padding:0}[type=number]::-webkit-inner-spin-button,[type=number]::-webkit-outer-spin-button{height:auto}[type=search]{-webkit-appearance:textfield;outline-offset:-2px}[type=search]::-webkit-search-decoration{-webkit-appearance:none}::-webkit-file-upload-button{-webkit-appearance:button;font:inherit}details{display:block}summary{display:list-item}template{display:none}[hidden]{display:none}

{.$icons.css.}

.pure-button {
	background-color: #cde; padding: .5em 1em; color: #444; color: rgba(0,0,0,.8); border: 1px solid #999; border: transparent; text-decoration: none; box-sizing: border-box;
	border-radius: 2px; display: inline-block; zoom: 1; white-space: nowrap; vertical-align: middle; text-align: center; cursor: pointer; user-select: none;
}
body { font-family:tahoma, verdana, arial, helvetica, sans; transition:background-color 1s ease; }
a { text-decoration:none; color:#26c; border:1px solid transparent; padding:0 0.1em; }
#folder-path { float:left; margin-bottom: 0.2em; }
#folder-path a { padding: .5em; }
#folder-path a:first-child { padding:.28em } #folder-path i.fa { font-size:135% }
button i.fa { font-size:110% }
.item { margin-bottom:.3em; padding:.3em  .8em; border-top:1px solid #ddd;  }
.item:hover { background:#f8f8f8; }
.item-props { float:right; font-size:90%; margin-left:12px; color:#777; margin-top:.2em; }
.item-link { float:left; word-break:break-word; /* fix long names without spaces on mobile */ }
.item img { vertical-align: text-bottom; margin:0 0.2em; }
.item .fa-lock { margin-right: 0.2em; }
.item .clearer { clear:both }
.comment { color:#666; padding:.1em .5em .2em; background-color: #f5f5f5; border-radius: 1em; margin-top: 0.1em; }
.comment>i { margin-right:0.5em; }
.item-size { margin-left:.3em }
.selector { float:left; width: 1.2em; height:1.2em; margin-right: .5em;}
.item-menu { padding:0.1em 0.3em; border-radius:0.6em; border: 1px outset; position: relative; top: -0.1em;}
.dialog-content .buttons { margin-top:1.5em }
.dialog-content .buttons button { margin:.5em auto; min-width: 9em; display:block; }
.dialog-content.error { background: #fcc; }
.dialog-content.error h2 { text-align:center }
.dialog-content.error button { background-color: #f77; color: white; }
#wrapper { max-width:60em; margin:auto; } /* not too wide or it will be harder to follow rows */
#serverinfo { font-size:80%; text-align:center; margin: 1.5em 0 0.5em; }
#selection-panel { text-align:center; }
#selection-panel label { margin-right:0.8em }
#selection-panel button { vertical-align:baseline; }
#selection-panel .buttons { white-space:nowrap }

.item-menu { display:none }
.can-comment .item-menu,
.can-rename .item-menu,
.can-delete .item-menu { display:inline-block; display:initial; }

#folder-stats { font-size:90%; padding:.1em .3em; margin:.5em; float:right; }
#files,#nothing { clear:both }
#nothing { padding:1em }

.dialog-overlay { background:rgba(0,0,0,.75); position:fixed; top:0; left:0; width:100%; height:100%; z-index:100; }
.dialog-content { position: absolute; top: 50%; left: 50%;
	transform: translate(-50%, -50%);
	-webkit-transform: translate(-50%, -50%);
	-moz-transform: translate(-50%, -50%);
	-ms-transform: translate(-50%, -50%);
	-o-transform: translate(-50%, -50%);
	background:#fff; border-radius: 1em; padding: 1em; text-align:center; min-width: 10em;
}
.ask input { border:1px solid rgba(0,0,0,0.5); padding: .2em; margin-top: .5em; }
.ask .close { float: right; font-size: 1.2em; color: red; position: relative; top: -0.4em; right: -0.3em; }

#additional-panels input {     color: #555; padding: .1em 0.3em; border-radius: 0.4em; }

.additional-panel { position:relative; max-height: calc(100vh - 5em); text-align:left; margin: 0.5em 1em; padding: 0.5em 1em; border-radius: 1em; background-color:#555; border: 2px solid #aaa; color:#fff; line-height: 1.5em; display:inline-block;  }
.additional-panel .close { position: absolute; right: -0.8em; top: -0.2em; color: #aaa; font-size: 130%; }

body.dark-theme { background:#222; color:#aaa; }
body.dark-theme #title-bar { color:#bbb }
body.dark-theme a { color:#79b }
body.dark-theme a.pure-button { color:#444 }
body.dark-theme .item:hover { background:#111; }
body.dark-theme .pure-button { background:#89a; }
body.dark-theme .item .comment { background-color:#444; color:#888; }
body.dark-theme #foldercomment { background-color:#333; color:#999; }
body.dark-theme .dialog-overlay { background:rgba(100,100,100,.5) }
body.dark-theme .dialog-content { background:#222; color:#888; }
body.dark-theme input,
body.dark-theme textarea,
body.dark-theme select,
body.dark-theme #additional-panels input
{ background: #111; color: #aaa; }

#msgs { display:none; }
#msgs li:first-child { font-weight:bold; }

#menu-panel { position:fixed; top:0; left:0; width: 100%; background:#555; text-align:center;
position: -webkit-sticky; position: -moz-sticky; position: -ms-sticky; position: -o-sticky; position: sticky; margin-bottom:0.3em;
z-index:1; /* without this .item-menu will be over*/ }
#menu-panel button span { margin-left:.8em }
#user-panel button { padding:0.3em 0.6em; font-size:smaller; margin-left:1em; }
#user-panel span { position: relative; top: 0.1em; }
#menu-bar { padding:0.2em 0 }

@media (min-width: 50em) {
#toggleTs { display: none }
}
@media (max-width: 50em) {
#menu-panel button { padding: .4em .6em; }
.additional-panel button span,
#menu-bar button span { display:none } /* icons only */
#menu-bar i { font-size:120%; } /* bigger icons */
#menu-bar button { width: 3em; max-width:10.7vw; padding: .4em 0; }
.hideTs .item-ts { display:none }
}

#upload-panel { font-size: 88%;}
#upload-progress { margin-top:.5em; display:none; }
#upload-progress progress { width:10em; position:relative; top:.1em; }
#progress-text { position: absolute; color: #000; font-size: 80%; margin-left:.5em; z-index:1; }
#upload-results a { color:#b0c2d4; }
#upload-results>* { display:block; word-break: break-all; }
#upload-results>span { margin-left:.15em; } /* better alignment */
#upload-results { max-height: calc(100vh - 11em); overflow: auto;}
#upload-panel>button { margin: auto; display: block; margin-top:.8em;} /* center it*/


[file=folder=link|private]
<div class='item item-type-%item-type% {.if|{.get|can access.}||cannot-access.} {.if|{.get|can archive item.}|can-archive.}'>
	<div class="item-link">
		<a href="%item-url%">
			<img src="%item-icon%" />
			%item-name%
		</a>
	</div>
	<div class='item-props'>
		<span class="item-ts"><i class='fa fa-clock-o'></i> {.cut||-3|%item-modified%.}</span>
[+file]
		<span class="item-size"><i class='fa fa-download' title="{.!Download counter:.} %item-dl-count%"></i> %item-size%B</span>
[+file=folder=link]
		{.if|{.get|is new.}|<i class='fa fa-star' title="{.!NEW.}"></i>.}
[+file=folder]
        <button class='item-menu pure-button' title="{.!More options.}"><i class="fa fa-bars"></i></button>
[+file=folder=link]
 	</div>
	<div class='clearer'></div>
[+file=folder=link]
    {.if| {.length|{.?search.}.} |{:{.123 if 2|<div class='item-folder'>{.!item folder.} |{.breadcrumbs|{:<a href="%bread-url%">%bread-name%/</a>:}|from={.count substring|/|%folder%.}/breadcrumbs.}|</div>.}:} .}
	{.123 if 2|<div class='comment'><i class="fa fa-quote-left"></i><span class="comment-text">|{.commentNL|%item-comment%.}|</span></div>.}
</div>

[error-page]
<!DOCTYPE html>
<html>
<head>
	<meta http-equiv="content-type" content="text/html; charset=UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style type="text/css">
  {.$style.css.}
  </style>
  </head>
<body>
%content%
<hr>
<div style="font-family:tahoma, verdana, arial, helvetica, sans; font-size:8pt;">
<a href="http://www.rejetto.com/hfs/">HFS</a> - %timestamp%
</div>
</body>
</html>

[not found]
<h1>{.!Not found.}</h1>
<a href="/">{.!go to root.}</a>

[overload]
<h1>{.!Server Too Busy.}</h1>
{.!The server is too busy to handle your request at this time. Retry later.}

[max contemp downloads]
<h1>{.!Download limit.}</h1>
{.!max s dl msg.}
<br>({.disconnection reason.})

[unauthorized]
<h1>{.!Unauthorized.}</h1>
{.!Either your user name and password do not match, or you are not permitted to access this resource..}

[deny]
<h1>{.!Forbidden.}</h1>
{.or|%reason%|{.!This resource is not accessible..}.}

[ban]
<h1>{.!You are banned.}</h1>
%reason%

[upload]

[upload-file]

[upload-results]
[{.cut|1|-1|%uploaded-files%.}
]

[upload-success]
{
"url":"%item-url%",
"name":"%item-name%",
"size":"%item-size%",
"speed":"%smart-speed%"
},
{.if| {.length|%user%.} |{:
	{.set item|%folder%%item-name%|comment={.!uploaded by.} %user%.}
:}.}

[upload-failed]
{ "err":"{.!%reason%.}", "name":"%item-name%" },

[progress|no log]
<style>
#progress .fn { font-weight:bold; }
.out_bar { margin-top:0.25em; width:100px; font-size:15px; background:#fff; border:#555 1px solid; margin-right:5px; float:left; }
.in_bar { height:0.5em; background:#47c;  }
</style>
<ul style='padding-left:1.5em;'>
%progress-files%
</ul>

[progress-nofiles]
{.!No file exchange in progress..}

[progress-upload-file]
{.if not|{.{.?only.} = down.}|{:
	<li> {.!Uploading.} %total% @ %speed-kb% KB/s
	<br /><span class='fn'>%filename%</span>
    <br />{.!Time left.} %time-left%"
	<br /><div class='out_bar'><div class='in_bar' style="width:%perc%px"></div></div> %perc%%
:}.}

[progress-download-file]
{.if not|{.{.?only.} = up.}|{:
	<li> {.!Downloading.} %total% @ %speed-kb% KB/s
	<br /><span class='fn'>%filename%</span>
    <br />{.!Time left.} %time-left%"
	<br><div class='out_bar'><div class='in_bar' style="width:%perc%px"></div></div> %perc%%
:}.}

[ajax.mkdir|no log]
{.check session.}
{.set|x|{.postvar|name.}.}
{.break|if={.pos|\|var=x.}{.pos|/|var=x.}|result=forbidden.}
{.break|if={.not|{.can mkdir.}.}|result=not authorized.}
{.set|x|%folder%{.^x.}.}
{.break|if={.exists|{.^x.}.}|result=exists.}
{.break|if={.not|{.length|{.mkdir|{.^x.}.}.}.}|result=failed.}
{.add to log|{.!User.} %user% {.!created folder.} "{.^x.}".}
{.pipe|ok.}

[ajax.rename|no log]
{.check session.}
{.break|if={.not|{.can rename.}.}|result=forbidden.}
{.break|if={.is file protected|{.postvar|from.}.}|result=forbidden.}
{.break|if={.is file protected|{.postvar|to.}.}|result=forbidden.}
{.set|x|%folder%{.postvar|from.}.}
{.set|yn|{.postvar|to.}.}
{.set|y|%folder%{.^yn.}.}
{.break|if={.not|{.exists|{.^x.}.}.}|result=not found.}
{.break|if={.exists|{.^y.}.}|result=exists.}
{.set|comment| {.get item|{.^x.}|comment.} .}
{.set item|{.^x.}|comment=.}
{.break|if={.not|{.length|{.rename|{.^x.}|{.^yn.}.}.}.}|result=failed.}
{.set item|{.^x.}|resource={.filepath|{.get item|{.^x.}|resource.}.}{.^yn.}.}
{.set item|{.^x.}|name={.^yn.}.}
{.set item|{.^y.}|comment={.^comment.}.}
{.add to log|{.if|%user%|{.!User.} %user%|{.!Anonymous.}.} {.!renamed.} "{.^x.}" {.!to.} "{.^yn.}".}
{.pipe|ok.}

[ajax.move|no log]
{.check session.}
{.set|dst|{.postvar|dst.}.}
{.break|if={.not|{.and|{.can move.}|{.get|can delete.}|{.get|can upload|path={.^dst.}.}/and.}.} |result=forbidden.}
{.set|log|{.!Moving items to.} {.^dst.}.}
{.for each|fn|{.replace|:|{.no pipe||.}|{.postvar|files.}.}|{:
    {.break|if={.is file protected|var=fn.}|result=forbidden.}
    {.set|x|%folder%{.^fn.}.}
    {.set|y|{.^dst.}/{.^fn.}.}
    {.if not |{.exists|{.^x.}.}|{.^x.}: {.!not found.}|{:
        {.if|{.exists|{.^y.}.}|{.^y.}: {.!already exists.}|{:
            {.set|comment| {.get item|{.^x.}|comment.} .}
            {.set item|{.^x.}|comment=.} {.comment| this must be done before moving, or it will fail.}
            {.if|{.length|{.move|{.^x.}|{.^y.}.}.} |{:
                {.move|{.^x.}.md5|{.^y.}.md5.}
                {.set|log|{.chr|13.}{.^fn.}|mode=append.}
                {.set item|{.^y.}|comment={.^comment.}.}
            :} | {:
                {.set|log|{.chr|13.}{.^fn.} (failed)|mode=append.}
                {.^fn.}: {.!not moved.}
            :}/if.}
        :}/if.}
    :}.}
    ;
:}.}
{.add to log|{.^log.}.}

[ajax.comment|no log]
{.check session.}
{.break|if={.not|{.can comment.}.} |result=forbidden.}
{.for each|fn|{.replace|:|{.no pipe||.}|{.postvar|files.}.}|{:
     {.break|if={.is file protected|var=fn.}|result=forbidden.}
     {.set item|%folder%{.^fn.}|comment={.postvar|text.}.}
:}.}
{.pipe|ok.}

[ajax.changepwd|no log]
{.check session.}
{.break|if={.not|{.can change pwd.}.} |result=forbidden.}
{.if|{.length|{.set account||password={.postvar|new.}.}/length.}|ok|failed.}

[special:alias]
check session=if|{.{.cookie|HFS_SID_.} != {.postvar|token.}.}|{:{.cookie|HFS_SID_|value=|expires=-1.} {.break|result=bad session.}:}
can mkdir=and|{.get|can upload.}|{.!option.newfolder.}
can comment=and|{.get|can upload.}|{.!option.comment.}
can rename=and|{.get|can delete.}|{.!option.rename.}
can delete=get|can delete
can change pwd=member of|can change password
can move=or|1|1
escape attr=replace|"|&quot;|$1
commentNL=if|{.pos|<br|$1.}|$1|{.replace|{.chr|10.}|<br />|$1.}
add bytes=switch|{.cut|-1||$1.}|,|0,1,2,3,4,5,6,7,8,9|$1 {.!Bytes.}|K,M,G,T|$1B

[special:import]
{.new account|can change password|enabled=1|is group=1|notes=accounts members of this group will be allowed to change their password.}

[lib.js|no log|cache]
// <script> // this is here for the syntax highlighter

function outsideV(e, additionalMargin) {
    outsideV.w || (outsideV.w = $(window));
    if (!(e instanceof $))
        e = $(e);
    return e.offset().top + e.height() > outsideV.w.height() - (additionalMargin || 0) - 17;
} // outsideV

function selectionChanged() { $('#selected-counter').text( getSelectedItems().length ) }

function getItemName(el) {
    if (!el)
        return false
    el = $(el)
    var a = el.closest('a')
    if (!a.length)
        a = el.closest('.item').find('.item-link:first a')
    // take the url, and ignore any #anchor part
    var s = a.attr('href') || a.attr('value');
    s = s.split('#')[0];
    // remove protocol and hostname
    var i = s.indexOf('://');
    if (i > 0)
        s = s.slice(s.indexOf('/',i+3));
    // current folder is specified. Remove it.
    if (s.indexOf(HFS.folder) == 0)
        s = s.slice(HFS.folder.length);
    // folders have a trailing slash that's not truly part of the name
    if (s.slice(-1) == '/')
        s = s.slice(0,-1);
    // it is encoded
    s = (decodeURIComponent || unescape)(s);
    return s;
} // getItemName

function submit(data, url) {
    var f = $('<form method="post">').attr('action',url||undefined).hide().appendTo('body')
    for (var k in data) {
        var v = data[k]
		if (!Array.isArray(v))
            f.append("<input type='hidden' name='"+k+"' value='"+v+"' />")
		else
		    v.forEach(function(v2) {
				f.append("<input type='hidden' name='"+k+"' value='"+v2+"' />")
        	})
    }
    f.submit()
}//submit

RegExp.escape = function(text) {
    if (!arguments.callee.sRE) {
        var specials = '/.*+?|()[]{}\\'.split('');
        arguments.callee.sRE = new RegExp('(\\' + specials.join('|\\') + ')', 'g');
    }
    return text.replace(arguments.callee.sRE, '\\$1');
}//escape

function dialog(content, cb) {
    var ret = $('<div class="dialog-content">').html(content).keydown(function(ev) {
		if (ev.keyCode===27)
			ret.close()
	})
	ret.close = function() {
        ret.closest('.dialog-overlay').remove()
        cb && cb()
    }
    ret.appendTo(
        $('<div class="dialog-overlay">').appendTo('body')
            .click(ret.close)
    ).click(function(ev){
        ev.stopImmediatePropagation()
    })
    return ret
} // dialog

function showMsg(content, cb) {
	if (~content.indexOf('<'))
		content = content.replace(/\n/g, '<br>')
    var ret = dialog($('<div>').css({ display:'inline-block', textAlign:'left' }).html(content), cb).css('text-align', 'center')
		.append(
			$('<div class="buttons">').html(
				$('<button class="pure-button">').text("{.!Ok.}")	
					.click(ev=> ret.close() ) ) )
	return ret
}//showMsg

function showError(msg, cb) {
    return msg && showMsg("<h2>{.!Error.}</h2>"+msg, cb).addClass('error')
}

/*  cb: function(value, dialog)
	options: type:string(text,textarea,number), value:any, keypress:function
*/
function ask(msg, options, cb) {
    // 2 parameters means "options" is missing
    if (arguments.length == 2) {
        cb = options;
        options = {};
    }
	if (typeof options==='string')
		options = { type:options }
    msg += '<br />';
    var v = options.type
	if (!v)
	    msg += '<br><button class="pure-button">{.!Ok.}</button>'
	else if (v == 'textarea')
		msg += '<textarea name="txt" cols="30" rows="8">'+options.value+'</textarea><br><button type="submit" class="pure-button">Ok</button>';
	else
		msg += '<input name="txt" type="'+v+'" value="'+(options.value||'')+'" />';
	var ret = dialog($('<form class="ask">')
		//.html($(`<i class="fa fa-times-rectangle close">`).click(ev=>ret.close()))
		.append(msg)
		.submit(function(ev) {
			if (false !== cb(options.type ? $.trim(ret.find(':input').val()) : $(ev.target), $(ev.target).closest('form'))) {
                ret.close()
                return false
            }
		})
	)

    ret.find(':input').focus().select() // autofocus attribute seems to work only first time :(

	return ret
}//ask

// this is a factory for ajax request handlers
function getStdAjaxCB(what2do) {
    if (!arguments.length)
        what2do = true;
    return function(res){
        res = $.trim(res);

        if (res !== "ok") {
            showError("{.!"+res+".}")
            if (res === 'bad session')
                location.reload();
            return;
        }
        // what2do is a list of actions we are supposed to do if the ajax result is "ok"
        if (what2do === null)
            return;
        if (!$.isArray(what2do))
            what2do = [what2do];
        what2do.forEach(w=>{
			if (w===true)
				return location.reload()
			if (typeof w==='function')
				return w() // you specify exactly what to do
			switch (w[0]) {
				case '!': return showMsg(w.substr(1))
				case '>': return location = w.substr(1)
			}
        })
    }
}//getStdAjaxCB

function getSelectedItems() {
    return $('#files .selector:checked')
}

function getSelectedItemsName() {
    return getSelectedItems().get().map(function(x) {
        return getItemName(x)
    })
}//getSelectedItemsName

function deleteFiles(files) {
	ask("{.!confirm.}", function(){
		return submit({ action:'delete', selection:files })
	})
}

function moveFiles(files) {
	ask("{.!Enter the destination folder.}", 'text', function(dst) {
		return ajax('move', { dst: dst, files: files.join(':') }, function(res) {
			var a = res.split(';')
			a.pop()
			if (!a.length)
				return showMsg($.trim(res))
			var failed = 0;
			var ok = 0;
			var msg = '';
			a.forEach(function(s) {
				s = $.trim(s)
				if (!s.length) {
					ok++
					return
				}
				failed++;
				msg += s+'\n'
			})
			if (failed)
				msg = "{.!We met the following problems:.}\n"+msg
			msg = (ok ? ok+' {.!files were moved..}\n' : "{.!No file was moved..}\n")+msg
			if (ok)
				showMsg(msg, reload)
			else
				showError(msg)
		})
	})
}//moveFiles

function reload() { location = '.' }

function selectionMask() {
    ask("{.!Please enter the file mask to select.}", {type:'text', value:'*'}, function(s){
        if (!s) return;
        var re = s.match('^/([^/]+)/([a-zA-Z]*)');
        if (re)
            re = new RegExp(re[1], re[2]);
        else {
            var n = s.match(/^(\\*)/)[0].length;
            s = s.substring(n);
            var invert = !!(n % 2); // a leading "\" will invert the logic
            s = RegExp.escape(s).replace(/[?]/g,".");;
            if (s.match(/\\\*/)) {
                s = s.replace(/\\\*/g,".*");
                s = "^ *"+s+" *$"; // in this case var the user decide exactly how it is placed in the string
            }
            re = new RegExp(s, "i");
        }
        $("#files .selector")
            .filter(function(i, e) {
                return invert ^ re.test(getItemName(e));
            })
            .prop('checked',true);
        selectionChanged()
    });
}//selectionMask

function setCookie(name,value,days) {
    if (days) {
        var date = new Date();
        date.setTime(date.getTime()+(days*24*60*60*1000));
        var expires = "; expires="+date.toGMTString();
    }
    else var expires = "";
    document.cookie = name+"="+value+expires+"; path=/";
} // setCookie

function delCookie(name) { setCookie(name,'', -1) }

function getCookie(name) {
	var a = document.cookie.match(new RegExp('(?:^| )' + name + '=([^;]+)'))
	return a && a[1]
} // getCookie

// quando in modalità selezione, viene mostrato una checkbox per ogni item, e viene anche mostrato un pannello per all/none/invert
var multiSelection = false
function toggleSelection() {
    $('#selection-panel').toggle()
	if (multiSelection = !multiSelection)
		$("<input type='checkbox' class='selector' />")
			.prependTo('.item-selectable a') // having the checkbox inside the A element will put it on the same line of A even with long A, otherwise A will start on a new line.
			.click(ev=>{ // we are keeping the checkbox inside an A tag for layout reasons, and firefox72 is triggering the link when the checkbox is clicked. So we reprogram the behaviour.
				setTimeout(()=>{ 
					ev.target.checked ^= 1
					selectionChanged() 
				})
				return false 
			})
	else
		$('#files .selector').remove()
}//toggleSelection

function upload(){
	$("<input type='file' name='file' multiple>").change(function(){
		var files = this.files
		if (!files.length) return
		$('#upload-panel').slideDown('fast')
		uploadQ.add(function(done){
			sendFiles(files, done)
		})
  	}).click()
} //upload

uploadQ = newQ().on('change', function(ev) {
    var n = Math.max(0, ev.count-1) // we don't consider the one we are working
    $('#upload-q').text(n)
})

function newQ(){
    var a = []
	var ret = $({})
    ret.add = function(job) {
        a.push(job)
		change()
        if (a.length!==1) return
		job(function consume(){
			a.shift() // trash it
			if (a.length)
				a[0](consume) // next
			else
				ret.trigger('empty')
			change()
		})
    }

    function change(){ ret.trigger({ type:'change', count:a.length }) }

	return ret
}//newQ

function changeSort(){
    dialog([
        $('<h3>').text('{.!Sort by.}'),
        $('<div class="buttons">').html(objToArr(sortOptions, function(label,code){
            return $('<button class="pure-button">')
				.text(label)
				.prepend(urlParams.sort===code ? '<i class="fa fa-sort-alt-'+(urlParams.rev?'down':'up')+'"></i> ' : '')
                .click(function(){
					urlParams.rev = (urlParams.sort===code && !urlParams.rev) ? 1 : undefined
					urlParams.sort = code||undefined
                    location.search = encodeURL(urlParams)
				})
		}))
	])
}//changeSort

function objToArr(o, cb){
    var ret = []
	for (var k in o) {
	    var v = o[k]
		ret.push(cb(v,k))
	}
	return ret
}

function sendFiles(files, done) {
    var formData = new FormData()
    for (var i = 0; i < files.length; i++)
        formData.append('file', files[i])

    $.ajax({
        type: 'POST',
        data: formData,
        success: function(data) {
            try {
                data = JSON.parse(data)
                data.forEach(function(r) {
                    $('#upload-'+(r.err ? 'ko' : 'ok')).text(function(i, s) {
                        return Number(s) + 1
                    })
                    $(r.err ? '<span title="'+r.err+'"><i class="fa fa-ban"></i> '+ r.name+'</span>' 
						: '<a title="{.!Size.}: '+r.size+'&#013;{.!Speed.}: '+r.speed+'B/s" href="'+r.url+'"><i class="fa fa-'+(r.err ? 'ban' : 'check-circle')+'"></i> '+r.name+'</a>')
						.appendTo('#upload-results');
                })
            }
            catch(e){
                console.error(e)
                showError('Invalid server reply')
            }
        },
        complete: done,
        cache: false,
        contentType: false,
        processData: false,
        xhr: function() {
            var e = $('#upload-progress')
            var prog = e.find('progress').prop('value', 0)
            e.slideDown('fast')
            var xhr = $.ajaxSettings.xhr()
            var last = 0
            var now = 0
            xhr.upload.onprogress = function(ev){
                prog.prop('value', (now = ev.loaded) / ev.total);
            }
            var h = setInterval(function() {
                $('#progress-text').text(smartSize(now)+'B @ '+smartSize(now-last)+'/s')
                last = now
            },1000)
            xhr.upload.onload = function(ev) {
                e.slideUp('fast')
                clearInterval(h)
            }
            return xhr
        }
    })
}//sendFiles

function smartSize(n, options) {
    options = options||{}
	var orders = ['','K','M','G','T','P']
	var order = options.order||1024
	var max = options.maxOrder||orders.length-1
	var i = 0
	while (n >= order && i<max) {
		n /= order
		++i
	}
	if (options.decimals===undefined)
		options.decimals = n<5 ? 1 : 0
	return round(n, options.decimals)
		+orders[i]
}//smartSize

function round(v, digits) {
	return !digits ? Math.round(v) : Math.round(v*Math.pow(10,digits)) / Math.pow(10,digits)
}//round

function log(){
	console.log.apply(console,arguments)
	return arguments[arguments.length-1]
}

function toggleTs(){
    var k = 'hideTs'
    $('#files').toggleClass(k)
    setCookie('ts', Number(!$('#files').hasClass(k)));
}

function decodeURL(urlData) {
	var ret = {}
    urlData.split('&').forEach(function(x){
        if (!x) return
        x = x.split("=").map(decodeURIComponent)
		ret[x[0]] = x.length===1 ? true : x[1]
    })
	return ret
}//decodeURL

function encodeURL(obj) {
    var ret = []
	for (var k in obj) {
	    var v = obj[k]
		if (v===undefined) continue
		k = encodeURIComponent(k)
	    if (v !== true)
	        k += '='+encodeURIComponent(v)
		ret.push(k)
	}
	return ret.join('&')
}//encodeURL

urlParams = decodeURL(location.search.substring(1))
sortOptions = {
	n: "{.!Name.}",
	e: "{.!Extension.}",
	s: "{.!Size.}",
	t: "{.!Timestamp.}",
	d: "{.!Hits.}",
	'': '{.!Default.}'
}

$(function(){
    $('.trash-me').detach(); // this was hiding things for those w/o js capabilities
    if (Number(getCookie('ts')))
        toggleTs()

    $('body').on('click','.item-menu', function(ev){
        var it = $(ev.target).closest('.item')
        var acc = it.hasClass('can-access')
        var name = getItemName(ev.target)
        dialog([
            $('<h3>').text(name),
            it.find('.item-ts').clone(),
            $('<div class="buttons">').html([
                it.closest('.can-delete').length > 0
				&& $('<button class="pure-button"><i class="fa fa-trash"></i> {.!Delete.}</button>')
					.click(function() { deleteFiles([name]) }),
                it.closest('.can-rename').length > 0
				&& $('<button class="pure-button"><i class="fa fa-edit"></i> {.!Rename.}</button>').click(renameItem),
                it.closest('.can-comment').length > 0
				&& $('<button class="pure-button"><i class="fa fa-quote-left"></i> {.!Comment.}</button>').click(setComment),
                it.closest('.can-move').length > 0
				&& $('<button class="pure-button"><i class="fa fa-truck"></i> {.!Move.}</button>')
					.click(function(){  moveFiles([name]) })
            ])
        ]).addClass('item-menu-dialog')

        //{.if|{.and|{.!option.move.}|{.can move.}.}| <button id='moveBtn' onclick='moveFiles()'>{.!Move.}</button> .}

        function setComment() {
            var value = it.find('.comment-text').text() || '';
            ask(this.innerHTML, { type: 'textarea', value: value }, function(s){
                if (s !== value)
                    ajax('comment', { text: s, files: name })
            })
        }//setComment

        function renameItem() {
            ask(this.innerHTML+ ' '+name, { type: 'text', value: name }, function(to){
                ajax("rename", { from: name, to: to });
            })
        }
    })

    $('#select-invert').click(function(ev) {
        $('#files .selector').prop('checked', function(i,v){ return !v })
        selectionChanged()
    })
    $('#select-mask').click(selectionMask)
    $('#move-selection').click(function(ev) { moveFiles(getSelectedItemsName()) })
		.toggle($('.can-delete').length > 0)
    $('#delete-selection').click(function(ev) { deleteFiles(getSelectedItemsName()) })
        .toggle($('.can-delete').length > 0)

    $('#files .cannot-access .item-link img').after('<i class="fa fa-lock" title="{.!No access.}"></i>')
	$('#files.can-delete .item:not(.cannot-access), #files .item.can-archive').addClass('item-selectable')
    if (! $('.item-selectable').length)
        $('#multiselection').hide()

    $('.additional-panel.closeable').prepend(
        $('<i class="fa fa-times-circle close">').click(function(ev){
            $(ev.target).closest('.closeable').fadeOut('fast').trigger('closed')
        }))

    $('#upload-panel').on('closed', function(ev){
        $('#upload-ok,#upload-ko').text('0')
        $('#upload-results').html('')
    })

	$('#sort span').text(sortOptions[urlParams.sort]||'{.!Sort.}')

    /* experiment
    $('.additional-panel.closeable').each(function(i, e) {
        swipable(e, 'right')
    })

    function swipable(e, dir) {
        e = $(e)
        e.mousedown(function(ev) {
            e.css('position','relative')
            var o = { x:ev.pageX, y:ev.pageY }
            console.warn(o)
            e.mouseup(function(ev) {
                e.css({ left: 0, top: 0 })
                e.off('mousemove.dragging')
            })
            e.on('mousemove.dragging', function(ev) { return e.css({ left:ev.pageX-o.x, top:ev.pageY-o.y }) })
        })
    }
    */

    selectionChanged()
})//onload
