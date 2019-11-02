<!DOCTYPE html>

<html  dir="ltr" lang="en" xml:lang="en">
<head>
    <title>Moodle Course: Log in to the site</title>
    <script type="text/javascript" nonce="f96aa8436a364b24a3c654fb75c" src="//local.adguard.org?ts=1572730247080&amp;type=content-script&amp;dmn=moodle-app2.let.ethz.ch&amp;css=1&amp;js=1&amp;gcss=1&amp;rel=1&amp;rji=1&amp;stealth=1&amp;uag="></script>
<script type="text/javascript" nonce="f96aa8436a364b24a3c654fb75c" src="//local.adguard.org?ts=1572730247080&amp;name=AdGuard%20Assistant&amp;name=AdGuard%20Popup%20Blocker&amp;name=Web%20of%20Trust&amp;name=AdGuard%20Extra&amp;type=user-script"></script><link rel="shortcut icon" href="https://moodle-app2.let.ethz.ch/theme/image.php/boost_ethz/theme/1572599263/favicon" />
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="keywords" content="moodle, Moodle Course: Log in to the site" />
<link rel="stylesheet" type="text/css" href="https://moodle-app2.let.ethz.ch/theme/yui_combo.php?rollup/3.17.2/yui-moodlesimple-min.css" /><script id="firstthemesheet" type="text/css">/** Required in order to fix style inclusion problems in IE with YUI **/</script><link rel="stylesheet" type="text/css" href="https://moodle-app2.let.ethz.ch/theme/styles.php/boost_ethz/1572599263_1572417863/all" />
<script type="text/javascript">
//<![CDATA[
var M = {}; M.yui = {};
M.pageloadstarttime = new Date();
M.cfg = {"wwwroot":"https:\/\/moodle-app2.let.ethz.ch","sesskey":"R4b9Hp0El8","themerev":"1572599263","slasharguments":1,"theme":"boost_ethz","iconsystemmodule":"core\/icon_system_fontawesome","jsrev":"1572599263","admin":"admin","svgicons":true,"usertimezone":"Europe\/Zurich","contextid":1};var yui1ConfigFn = function(me) {if(/-skin|reset|fonts|grids|base/.test(me.name)){me.type='css';me.path=me.path.replace(/\.js/,'.css');me.path=me.path.replace(/\/yui2-skin/,'/assets/skins/sam/yui2-skin')}};
var yui2ConfigFn = function(me) {var parts=me.name.replace(/^moodle-/,'').split('-'),component=parts.shift(),module=parts[0],min='-min';if(/-(skin|core)$/.test(me.name)){parts.pop();me.type='css';min=''}
if(module){var filename=parts.join('-');me.path=component+'/'+module+'/'+filename+min+'.'+me.type}else{me.path=component+'/'+component+'.'+me.type}};
YUI_config = {"debug":false,"base":"https:\/\/moodle-app2.let.ethz.ch\/lib\/yuilib\/3.17.2\/","comboBase":"https:\/\/moodle-app2.let.ethz.ch\/theme\/yui_combo.php?","combine":true,"filter":null,"insertBefore":"firstthemesheet","groups":{"yui2":{"base":"https:\/\/moodle-app2.let.ethz.ch\/lib\/yuilib\/2in3\/2.9.0\/build\/","comboBase":"https:\/\/moodle-app2.let.ethz.ch\/theme\/yui_combo.php?","combine":true,"ext":false,"root":"2in3\/2.9.0\/build\/","patterns":{"yui2-":{"group":"yui2","configFn":yui1ConfigFn}}},"moodle":{"name":"moodle","base":"https:\/\/moodle-app2.let.ethz.ch\/theme\/yui_combo.php?m\/1572599263\/","combine":true,"comboBase":"https:\/\/moodle-app2.let.ethz.ch\/theme\/yui_combo.php?","ext":false,"root":"m\/1572599263\/","patterns":{"moodle-":{"group":"moodle","configFn":yui2ConfigFn}},"filter":null,"modules":{"moodle-core-dragdrop":{"requires":["base","node","io","dom","dd","event-key","event-focus","moodle-core-notification"]},"moodle-core-blocks":{"requires":["base","node","io","dom","dd","dd-scroll","moodle-core-dragdrop","moodle-core-notification"]},"moodle-core-popuphelp":{"requires":["moodle-core-tooltip"]},"moodle-core-chooserdialogue":{"requires":["base","panel","moodle-core-notification"]},"moodle-core-notification":{"requires":["moodle-core-notification-dialogue","moodle-core-notification-alert","moodle-core-notification-confirm","moodle-core-notification-exception","moodle-core-notification-ajaxexception"]},"moodle-core-notification-dialogue":{"requires":["base","node","panel","escape","event-key","dd-plugin","moodle-core-widget-focusafterclose","moodle-core-lockscroll"]},"moodle-core-notification-alert":{"requires":["moodle-core-notification-dialogue"]},"moodle-core-notification-confirm":{"requires":["moodle-core-notification-dialogue"]},"moodle-core-notification-exception":{"requires":["moodle-core-notification-dialogue"]},"moodle-core-notification-ajaxexception":{"requires":["moodle-core-notification-dialogue"]},"moodle-core-tooltip":{"requires":["base","node","io-base","moodle-core-notification-dialogue","json-parse","widget-position","widget-position-align","event-outside","cache-base"]},"moodle-core-actionmenu":{"requires":["base","event","node-event-simulate"]},"moodle-core-languninstallconfirm":{"requires":["base","node","moodle-core-notification-confirm","moodle-core-notification-alert"]},"moodle-core-maintenancemodetimer":{"requires":["base","node"]},"moodle-core-dock":{"requires":["base","node","event-custom","event-mouseenter","event-resize","escape","moodle-core-dock-loader","moodle-core-event"]},"moodle-core-dock-loader":{"requires":["escape"]},"moodle-core-handlebars":{"condition":{"trigger":"handlebars","when":"after"}},"moodle-core-lockscroll":{"requires":["plugin","base-build"]},"moodle-core-event":{"requires":["event-custom"]},"moodle-core-formchangechecker":{"requires":["base","event-focus","moodle-core-event"]},"moodle-core-checknet":{"requires":["base-base","moodle-core-notification-alert","io-base"]},"moodle-core_availability-form":{"requires":["base","node","event","event-delegate","panel","moodle-core-notification-dialogue","json"]},"moodle-backup-confirmcancel":{"requires":["node","node-event-simulate","moodle-core-notification-confirm"]},"moodle-backup-backupselectall":{"requires":["node","event","node-event-simulate","anim"]},"moodle-course-util":{"requires":["node"],"use":["moodle-course-util-base"],"submodules":{"moodle-course-util-base":{},"moodle-course-util-section":{"requires":["node","moodle-course-util-base"]},"moodle-course-util-cm":{"requires":["node","moodle-course-util-base"]}}},"moodle-course-dragdrop":{"requires":["base","node","io","dom","dd","dd-scroll","moodle-core-dragdrop","moodle-core-notification","moodle-course-coursebase","moodle-course-util"]},"moodle-course-modchooser":{"requires":["moodle-core-chooserdialogue","moodle-course-coursebase"]},"moodle-course-categoryexpander":{"requires":["node","event-key"]},"moodle-course-management":{"requires":["base","node","io-base","moodle-core-notification-exception","json-parse","dd-constrain","dd-proxy","dd-drop","dd-delegate","node-event-delegate"]},"moodle-course-formatchooser":{"requires":["base","node","node-event-simulate"]},"moodle-form-passwordunmask":{"requires":[]},"moodle-form-dateselector":{"requires":["base","node","overlay","calendar"]},"moodle-form-showadvanced":{"requires":["node","base","selector-css3"]},"moodle-form-shortforms":{"requires":["node","base","selector-css3","moodle-core-event"]},"moodle-question-preview":{"requires":["base","dom","event-delegate","event-key","core_question_engine"]},"moodle-question-chooser":{"requires":["moodle-core-chooserdialogue"]},"moodle-question-searchform":{"requires":["base","node"]},"moodle-question-qbankmanager":{"requires":["node","selector-css3"]},"moodle-availability_completion-form":{"requires":["base","node","event","moodle-core_availability-form"]},"moodle-availability_date-form":{"requires":["base","node","event","io","moodle-core_availability-form"]},"moodle-availability_grade-form":{"requires":["base","node","event","moodle-core_availability-form"]},"moodle-availability_group-form":{"requires":["base","node","event","moodle-core_availability-form"]},"moodle-availability_grouping-form":{"requires":["base","node","event","moodle-core_availability-form"]},"moodle-availability_profile-form":{"requires":["base","node","event","moodle-core_availability-form"]},"moodle-availability_xp-form":{"requires":["base","node","event","handlebars","moodle-core_availability-form"]},"moodle-mod_assign-history":{"requires":["node","transition"]},"moodle-mod_forum-subscriptiontoggle":{"requires":["base-base","io-base"]},"moodle-mod_oublog-savecheck":{"requires":["base","node","io","panel","moodle-core-notification-alert"]},"moodle-mod_oublog-tagselector":{"requires":["base","node","autocomplete","autocomplete-filters","autocomplete-highlighters"]},"moodle-mod_quiz-util":{"requires":["node","moodle-core-actionmenu"],"use":["moodle-mod_quiz-util-base"],"submodules":{"moodle-mod_quiz-util-base":{},"moodle-mod_quiz-util-slot":{"requires":["node","moodle-mod_quiz-util-base"]},"moodle-mod_quiz-util-page":{"requires":["node","moodle-mod_quiz-util-base"]}}},"moodle-mod_quiz-dragdrop":{"requires":["base","node","io","dom","dd","dd-scroll","moodle-core-dragdrop","moodle-core-notification","moodle-mod_quiz-quizbase","moodle-mod_quiz-util-base","moodle-mod_quiz-util-page","moodle-mod_quiz-util-slot","moodle-course-util"]},"moodle-mod_quiz-modform":{"requires":["base","node","event"]},"moodle-mod_quiz-toolboxes":{"requires":["base","node","event","event-key","io","moodle-mod_quiz-quizbase","moodle-mod_quiz-util-slot","moodle-core-notification-ajaxexception"]},"moodle-mod_quiz-repaginate":{"requires":["base","event","node","io","moodle-core-notification-dialogue"]},"moodle-mod_quiz-autosave":{"requires":["base","node","event","event-valuechange","node-event-delegate","io-form"]},"moodle-mod_quiz-quizbase":{"requires":["base","node"]},"moodle-mod_quiz-questionchooser":{"requires":["moodle-core-chooserdialogue","moodle-mod_quiz-util","querystring-parse"]},"moodle-mod_scheduler-delselected":{"requires":["base","node","event"]},"moodle-mod_scheduler-studentlist":{"requires":["base","node","event","io"]},"moodle-mod_scheduler-saveseen":{"requires":["base","node","event"]},"moodle-message_airnotifier-toolboxes":{"requires":["base","node","io"]},"moodle-block_xp-rulepicker":{"requires":["base","node","handlebars","moodle-core-notification-dialogue"]},"moodle-block_xp-notification":{"requires":["base","node","handlebars","button-plugin","moodle-core-notification-dialogue"]},"moodle-block_xp-filters":{"requires":["base","node","moodle-core-dragdrop","moodle-block_xp-rulepicker"]},"moodle-filter_glossary-autolinker":{"requires":["base","node","io-base","json-parse","event-delegate","overlay","moodle-core-event","moodle-core-notification-alert","moodle-core-notification-exception","moodle-core-notification-ajaxexception"]},"moodle-filter_mathjaxloader-loader":{"requires":["moodle-core-event"]},"moodle-editor_atto-editor":{"requires":["node","transition","io","overlay","escape","event","event-simulate","event-custom","node-event-html5","node-event-simulate","yui-throttle","moodle-core-notification-dialogue","moodle-core-notification-confirm","moodle-editor_atto-rangy","handlebars","timers","querystring-stringify"]},"moodle-editor_atto-plugin":{"requires":["node","base","escape","event","event-outside","handlebars","event-custom","timers","moodle-editor_atto-menu"]},"moodle-editor_atto-menu":{"requires":["moodle-core-notification-dialogue","node","event","event-custom"]},"moodle-editor_atto-rangy":{"requires":[]},"moodle-format_grid-gridkeys":{"requires":["event-nav-keys"]},"moodle-report_eventlist-eventfilter":{"requires":["base","event","node","node-event-delegate","datatable","autocomplete","autocomplete-filters"]},"moodle-report_loglive-fetchlogs":{"requires":["base","event","node","io","node-event-delegate"]},"moodle-gradereport_grader-gradereporttable":{"requires":["base","node","event","handlebars","overlay","event-hover"]},"moodle-gradereport_history-userselector":{"requires":["escape","event-delegate","event-key","handlebars","io-base","json-parse","moodle-core-notification-dialogue"]},"moodle-tool_capability-search":{"requires":["base","node"]},"moodle-tool_lp-dragdrop-reorder":{"requires":["moodle-core-dragdrop"]},"moodle-tool_monitor-dropdown":{"requires":["base","event","node"]},"moodle-assignfeedback_editpdf-editor":{"requires":["base","event","node","io","graphics","json","event-move","event-resize","transition","querystring-stringify-simple","moodle-core-notification-dialog","moodle-core-notification-alert","moodle-core-notification-warning","moodle-core-notification-exception","moodle-core-notification-ajaxexception"]},"moodle-atto_accessibilitychecker-button":{"requires":["color-base","moodle-editor_atto-plugin"]},"moodle-atto_accessibilityhelper-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_align-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_bold-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_charmap-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_clear-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_collapse-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_count-button":{"requires":["io","json-parse","moodle-editor_atto-plugin"]},"moodle-atto_emoticon-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_equation-button":{"requires":["moodle-editor_atto-plugin","moodle-core-event","io","event-valuechange","tabview","array-extras"]},"moodle-atto_filedragdrop-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_fullscreen-button":{"requires":["event-resize","moodle-editor_atto-plugin"]},"moodle-atto_hr-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_html-button":{"requires":["promise","moodle-editor_atto-plugin","moodle-atto_html-beautify","moodle-atto_html-codemirror","event-valuechange"]},"moodle-atto_html-beautify":{},"moodle-atto_html-codemirror":{"requires":["moodle-atto_html-codemirror-skin"]},"moodle-atto_htmlplus-button":{"requires":["moodle-editor_atto-plugin","moodle-atto_htmlplus-beautify","moodle-atto_htmlplus-codemirror","event-valuechange"]},"moodle-atto_htmlplus-beautify":{},"moodle-atto_htmlplus-codemirror":{"requires":["moodle-atto_htmlplus-codemirror-skin"]},"moodle-atto_image-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_indent-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_italic-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_link-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_managefiles-usedfiles":{"requires":["node","escape"]},"moodle-atto_managefiles-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_media-button":{"requires":["moodle-editor_atto-plugin","moodle-form-shortforms"]},"moodle-atto_noautolink-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_orderedlist-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_recordrtc-recording":{"requires":["moodle-atto_recordrtc-button"]},"moodle-atto_recordrtc-button":{"requires":["moodle-editor_atto-plugin","moodle-atto_recordrtc-recording"]},"moodle-atto_rtl-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_strike-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_subscript-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_superscript-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_table-button":{"requires":["moodle-editor_atto-plugin","moodle-editor_atto-menu","event","event-valuechange"]},"moodle-atto_title-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_underline-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_undo-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_unorderedlist-button":{"requires":["moodle-editor_atto-plugin"]},"moodle-atto_wordimport-button":{"requires":["moodle-editor_atto-plugin"]}}},"gallery":{"name":"gallery","base":"https:\/\/moodle-app2.let.ethz.ch\/lib\/yuilib\/gallery\/","combine":true,"comboBase":"https:\/\/moodle-app2.let.ethz.ch\/theme\/yui_combo.php?","ext":false,"root":"gallery\/1572599263\/","patterns":{"gallery-":{"group":"gallery"}}}},"modules":{"core_filepicker":{"name":"core_filepicker","fullpath":"https:\/\/moodle-app2.let.ethz.ch\/lib\/javascript.php\/1572599263\/repository\/filepicker.js","requires":["base","node","node-event-simulate","json","async-queue","io-base","io-upload-iframe","io-form","yui2-treeview","panel","cookie","datatable","datatable-sort","resize-plugin","dd-plugin","escape","moodle-core_filepicker","moodle-core-notification-dialogue"]},"core_comment":{"name":"core_comment","fullpath":"https:\/\/moodle-app2.let.ethz.ch\/lib\/javascript.php\/1572599263\/comment\/comment.js","requires":["base","io-base","node","json","yui2-animation","overlay","escape"]},"mathjax":{"name":"mathjax","fullpath":"https:\/\/moodle-app2.let.ethz.ch\/lib\/mathjax\/MathJax.js?delayStartupUntil=configured"}}};
M.yui.loader = {modules: {}};

//]]>
</script>

<script src="https://moodle-app2.let.ethz.ch/media/player/jwplayer/jwplayer/jwplayer.js" type="text/javascript"></script>

<script>jwplayer.key="2/2Ldn4vIexUjZEkXxuAq940fO4ImfK9Y+p2lXOROeo=";</script><link href="https://moodle-app2.let.ethz.ch/theme/boost_ethz/style/ethz.css" rel="stylesheet" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body  id="page-auth-shibboleth-login" class="format-site  path-auth path-auth-shibboleth gecko dir-ltr lang-en yui-skin-sam yui3-skin-sam moodle-app2-let-ethz-ch pagelayout-base course-1 context-1 notloggedin ">
<div id="page-header-color" class="hidden-print">
    <div id="page-header-color-left"></div>
    <div id="page-header-color-nav"></div>
    <div id="page-header-color-block"></div>
    <div id="page-header-color-right"></div>
</div>
<div id="page-wrapper">
    <div>
    <a class="sr-only sr-only-focusable" href="#maincontent">Skip to main content</a>
</div><script type="text/javascript" src="https://moodle-app2.let.ethz.ch/theme/yui_combo.php?rollup/3.17.2/yui-moodlesimple-min.js"></script><script type="text/javascript" src="https://moodle-app2.let.ethz.ch/lib/javascript.php/1572599263/lib/javascript-static.js"></script>
<script type="text/javascript">
//<![CDATA[
document.body.className += ' jsenabled';
//]]>
</script>


    <header role="banner" id="header" class="fixed-top navbar row">
        <div id="header-container">
            <div id="header-right" class="hidden-print float-right">
                <ul class="userlang navbar-nav d-md-flex">
    <li class="dropdown nav-item"><a class="dropdown-toggle nav-link" id="id-drop-down" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" href="#">en&nbsp;</a>
        <div class="dropdown-menu dropdown-menu-right userlang-menu" aria-labelledby="id-drop-down">
            <a class="dropdown-item" href="https://moodle-app2.let.ethz.ch/auth/shibboleth/login.php?lang=de" title="Deutsch ‎(de)‎">Deutsch ‎</a>
            <a class="dropdown-item" href="https://moodle-app2.let.ethz.ch/auth/shibboleth/login.php?lang=en" title="English ‎(en)‎">English ‎</a>
            <a class="dropdown-item" href="https://moodle-app2.let.ethz.ch/auth/shibboleth/login.php?lang=fr" title="Français ‎(fr)‎">Français ‎</a>
            <a class="dropdown-item" href="https://moodle-app2.let.ethz.ch/auth/shibboleth/login.php?lang=it" title="Italiano ‎(it)‎">Italiano ‎</a>
            <a class="dropdown-item" href="https://moodle-app2.let.ethz.ch/auth/shibboleth/login.php?lang=el" title="Ελληνικά ‎(el)‎">Ελληνικά ‎</a>
        </div>
    </li>
</ul>
                <div class="usermenu"><span class="login">You are not logged in. (<a href="https://moodle-app2.let.ethz.ch/login/index.php">Log in</a>)</span></div>
                
                <div class="search-input-wrapper nav-link" id="5dbe06c2103a6"><div role="button" tabindex="0"><i class="icon fa fa-search fa-fw "  title="Courses" aria-label="Courses"></i></div><form class="search-input-form" action="https://moodle-app2.let.ethz.ch/course/search.php"><label for="id_q_5dbe06c2103a6" class="accesshide">Enter your search query</label><input type="text" name="search" placeholder="Courses" size="13" tabindex="-1" id="id_q_5dbe06c2103a6" class="form-control"></input><input type="hidden" name="context" value="1" /></form></div>
            </div>
            <div id="header-left">
                <div id="logo-ethz"><a href="http://ethz.ch/" id="home-link" target="_blank"><img src="https://moodle-app2.let.ethz.ch/theme/boost_ethz/pix/ethz_logo.svg" alt="Logo ETH Z&uuml;rich"></a></div>
                <div id="logo-button" data-region="drawer-toggle"><button id="nav-drawer-button" aria-expanded="false" aria-controls="nav-drawer" type="button" class="pull-xs-left m-r-1 btn-menue" data-action="toggle-drawer" data-side="left" data-preference="drawer-open-nav"><img src="https://moodle-app2.let.ethz.ch/theme/boost_ethz/pix/nav.png" aria-hidden="true" alt=""><span class="sr-only">Side panel</span></button></div>
                <div id="logo-text" class="hidden-md-down"><span id="home-link">Moodle</span></div>
            </div>
        </div>
    </header>    <div id="page" class="container-fluid">
        <header id="page-header" class="row">
    <div class="col-12 pt-3 pb-3">
        <div class="card ">
            <div class="card-body ">
                <div class="d-flex">
                    <div class="mr-auto">
                        <div class="page-context-header"><div class="page-header-headings"><h1>Moodle Course</h1></div></div>
                    </div>

                </div>
                <div class="d-flex flex-wrap">
                    <div id="page-navbar">
                        <nav role="navigation" aria-label="Navigation bar">
    <ol class="breadcrumb">
                <li class="breadcrumb-item">
                    <a href="https://moodle-app2.let.ethz.ch/"  >Home</a>
                </li>
                <li class="breadcrumb-item">Log in to the site</li>
    </ol>
</nav>
                    </div>
                    <div class="ml-auto d-flex">
                        
                    </div>
                    <div id="course-header">
                        
                    </div>
                </div>
            </div>
        </div>
    </div>
</header>
        <div id="page-content" class="row">
            <div id="region-main-box" class="col-12">
                <section id="region-main" >
                    <div class="card">
                        <div class="card-body">
                            <span class="notifications" id="user-notifications"></span>
                            
                            <div role="main"><span id="maincontent"></span><div class="loginbox clearfix twocolumns">
  <div class="loginpanel">
    <!--<h2>Returning to this web site?</h2>-->

    <h2>Shibboleth Login</h2>
      <div class="subcontent loginsub">
        <div class="desc">
                  <div class="guestsub">
          <p><label for="idp">For authentication via Shibboleth, please select your organisation from the drop-down menu:</label></p>
            <form action="login.php" method="post" id="guestlogin">
            <select id="idp" name="idp">
                <option value="-" >I'm a member of ...</option>
                <option value="https://aai-logon.ethz.ch/idp/shibboleth" selected="selected">ETH Zürich</option><option value="https://aai-idp.uzh.ch/idp/shibboleth">Universität Zürich</option><option value="https://idp.epfl.ch/idp/shibboleth">EPFL - EPF Lausanne</option><option value="https://aai-logon.unibas.ch/idp/shibboleth">Universität Basel</option><option value="https://aai-idp.unibe.ch/idp/shibboleth">Universität Bern</option><option value="https://login2.usi.ch/idp/shibboleth">Università   della Svizzera Italiana</option><option value="https://aai.unifr.ch/idp/shibboleth">Université de Fribourg</option><option value="https://idp.unige.ch/idp/shibboleth">Université de Genève</option><option value="https://aai.unil.ch/idp/shibboleth">Université de Lausanne</option><option value="https://aai-logon.unilu.ch/idp/shibboleth">Universität Luzern</option><option value="https://aai-login.unine.ch/idp/shibboleth">Université de Neuchâtel</option><option value="https://aai.unisg.ch/idp/shibboleth">Universität St. Gallen</option><option value="https://aai-logon.bfh.ch/idp/shibboleth">BFH - Berner Fachhochschule</option><option value="https://idp.ffhs.ch/idp/shibboleth">FFHS - Fernfachhochschule Schweiz</option><option value="https://aai-logon.fhsg.ch/idp/shibboleth">FHS St. Gallen - Hochschule für Angewandte Wissenschaften</option><option value="https://aai-logon.fhnw.ch/idp/shibboleth">FHNW - Fachhochschule Nordwestschweiz</option><option value="https://aai-logon.hes-so.ch/idp/shibboleth">HES-SO - Haute école spécialisée de Suisse occidentale</option><option value="https://aai-logon.uni.li/idp/shibboleth">Universität Liechtenstein</option><option value="https://idp.hslu.ch/idp/shibboleth">HSLU - Hochschule Luzern</option><option value="https://aai-login.hsr.ch/idp/shibboleth">HSR - Hochschule für Technik Rapperswil</option><option value="https://aai-logon.hsz-t.ch/idp/shibboleth">HSZ-T - Hochschule für Technik Zürich</option><option value="https://aai-login.fh-htwchur.ch/idp/shibboleth">HTW Chur - Hochschule für Technik und Wirtschaft</option><option value="https://aai-logon.fh-hwz.ch/idp/shibboleth">HWZ - Hochschule für Wirtschaft Zürich</option><option value="https://aai.ntb.ch/idp/shibboleth">NTB - Hochschule für Technik Buchs</option><option value="https://aai-login.phbern.ch/idp/shibboleth">PHBern - Pädagogische Hochschule Bern</option><option value="https://aai-login.ph-gr.ch/idp/shibboleth">PHGR - Pädagogische Hochschule Graubünden</option><option value="https://idp.phsz.ch/idp/shibboleth">PHSZ - Pädagogische Hochschule Schwyz</option><option value="https://aai-login.phsg.ch/idp/shibboleth">PHSG - Pädagogische Hochschule des Kantons St.Gallen</option><option value="https://aai-logon.phtg.ch/idp/shibboleth">PHTG - Pädagogische Hochschule Thurgau</option><option value="https://aai01.phzh.ch/idp/shibboleth">PH Zürich - Pädagogische Hochschule Zürich</option><option value="https://login2.supsi.ch/idp/shibboleth">SUPSI - Scuola Universitaria Professionale della Svizzera Italiana</option><option value="https://aai.zhaw.ch/idp/shibboleth">ZHAW - Zürcher Hochschule für Angewandte Wissenschaften</option><option value="https://aai-logon.zhdk.ch/idp/shibboleth">ZHdK - Zürcher Hochschule der Künste</option><option value="https://aai.hcuge.ch/idp/shibboleth">HUG - Hôpitaux Universitaires de Genève</option><option value="https://aai.insel.ch/idp/shibboleth">Inselspital - Universitätsspital Bern</option><option value="https://aai-logon.unispital.ch/idp/shibboleth">Universitätsspital Zürich</option><option value="https://aai-logon.vho-switchaai.ch/idp/shibboleth">Virtual Home Organisation @SWITCHaai</option><option value="https://aai-logon.zhbluzern.ch/idp/shibboleth">Zentral- und Hochschulbibliothek Luzern</option><option value="https://cern.ch/login">CERN</option><option value="https://idp.fernuni.ch/idp/shibboleth">Distance Learning University</option><option value="https://aai.eawag.ch/idp/shibboleth">Eawag</option><option value="https://aai.empa.ch/idp/shibboleth">Empa</option><option value="https://aai-login.euresearch.ch/idp/shibboleth">Euresearch Head Office</option><option value="http://adfs3.fmi.ch/adfs/services/trust">FMI - Friedrich Miescher Institut</option><option value="https://login.teologialugano.ch/idp/shibboleth">FTL - Facoltà di Teologia di Lugano</option><option value="https://aai.idiap.ch/idp/shibboleth">IDIAP - Idiap Research Institute</option><option value="https://idp.graduateinstitute.ch/idp/shibboleth">Institut de hautes études internationales et du développement</option><option value="https://aai-login.pmodwrc.ch/idp/shibboleth">PMOD/WRC - Observatorium Davos</option><option value="https://aai-logon.psi.ch/idp/shibboleth">PSI - Paul Scherrer Institut</option><option value="https://aai-login.ehb-schweiz.ch/idp/shibboleth">SFIVET - Swiss Federal Institute for Vocational Education and Training</option><option value="https://aai-login.snf.ch/idp/shibboleth">SNF - Schweizerischer Nationalfonds</option><option value="https://eduid.ch/idp/shibboleth">Swiss edu-ID</option><option value="https://aai-login.swissuniversities.ch/idp/shibboleth">swissuniversities</option><option value="https://aai-logon.switch.ch/idp/shibboleth">SWITCH</option><option value="https://aai-logon.wsl.ch/idp/shibboleth">WSL - Eidg. Forschungsanstalt für Wald Schnee und Landschaft</option>            </select><p><input type="submit" value="Select" accesskey="s" /></p>
            </form>
            <p>
            In case you are not associated with the given organizations and you need access to a course on this server, please contact the <a href="mailto:moodle@let.ethz.ch">Moodle Administrator</a>.            </p>
          </div>
         </div>
      </div>

      <div class="subcontent guestsub">
        <div class="desc">
          Some courses may allow guest access        </div>
        <form action="../../login/index.php" method="post" id="guestlogin">
          <div class="guestform">
            <input type="hidden" name="logintoken" value="duMAF8dhtKiBfb4ijzEyqgWCoJORJ5ES" />
            <input type="hidden" name="username" value="guest" />
            <input type="hidden" name="password" value="guest" />
            <input type="submit" value="Log in as a guest" />
          </div>
        </form>
      </div>
     </div>


    <div class="signuppanel">
      <h2>Is this your first time here?</h2>
      <div class="subcontent">
<div class="text_to_html">Nutzen Sie den <a href="https://moodle-app2.let.ethz.ch/auth/shibboleth/index.php">Shibboleth Login</a>, um Zugang über Shibboleth zu erhalten, wenn Ihr Unternehmen dies unterstützt. <br />Sonst verwenden Sie das normale hier angezeigte Loginformular.</div>      </div>
    </div>
</div>
</div>
                            
                            
                        </div>
                    </div>
                </section>
                <div class="clearfix"></div>
                <footer id="page-footer" class="py-3 text-light">
                    <div class="container">
                        
<!-- Matomo -->
<script type="text/javascript">
  var _paq = _paq || [];
  /* tracker methods like "setCustomDimension" should be called before "trackPageView" */
  _paq.push(['trackPageView']);
  _paq.push(['enableLinkTracking']);
  (function() {
    var u="//piwik.let.ethz.ch/";
    _paq.push(['setTrackerUrl', u+'piwik.php']);
    _paq.push(['setSiteId', '1']);
    var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0];
    g.type='text/javascript'; g.async=true; g.defer=true; g.src=u+'piwik.js'; s.parentNode.insertBefore(g,s);
  })();
</script>
<!-- End Matomo Code -->

<div style="background-color:#eaecee">
  <div style="display: flex; justify-content: space-between;">
    <div><a href="https://moodle-app2.let.ethz.ch/user_agreement/nutzungsbestimmungen_de_optout.html" target="_blank">Nutzungsbestimmungen</a> / <a href = "https://moodle-app2.let.ethz.ch/user_agreement/nutzungsbestimmungen_en_optout.html" target=_blank">Conditions of use</a> </div>
    <div><a href="https://www.ethz.ch/de/die-eth-zuerich/organisation/abteilungen/lehrentwicklung-und-technologie.html" target="_blank">LET</a> </div>
    <div><a href="https://www.ethz.ch/" target="_blank">© 2019 ETH Zürich</a> </div>
  </div>
</div>

<iframe
        style="border: 0; height: 100px;  width: 100%;"
        src="https://piwik.let.ethz.ch/index.php?module=CoreAdminHome&action=optOut&language=en&backgroundColor=eaecee&fontColor=000000&fontSize=12px&fontFamily=Arial, Helvetica, sans-serif">
</iframe>

<script type="text/javascript">
//<![CDATA[
var require = {
    baseUrl : 'https://moodle-app2.let.ethz.ch/lib/requirejs.php/1572599263/',
    // We only support AMD modules with an explicit define() statement.
    enforceDefine: true,
    skipDataMain: true,
    waitSeconds : 0,

    paths: {
        jquery: 'https://moodle-app2.let.ethz.ch/lib/javascript.php/1572599263/lib/jquery/jquery-3.2.1.min',
        jqueryui: 'https://moodle-app2.let.ethz.ch/lib/javascript.php/1572599263/lib/jquery/ui-1.12.1/jquery-ui.min',
        jqueryprivate: 'https://moodle-app2.let.ethz.ch/lib/javascript.php/1572599263/lib/requirejs/jquery-private'
    },

    // Custom jquery config map.
    map: {
      // '*' means all modules will get 'jqueryprivate'
      // for their 'jquery' dependency.
      '*': { jquery: 'jqueryprivate' },
      // Stub module for 'process'. This is a workaround for a bug in MathJax (see MDL-60458).
      '*': { process: 'core/first' },

      // 'jquery-private' wants the real jQuery module
      // though. If this line was not here, there would
      // be an unresolvable cyclic dependency.
      jqueryprivate: { jquery: 'jquery' }
    }
};

//]]>
</script>
<script type="text/javascript" src="https://moodle-app2.let.ethz.ch/lib/javascript.php/1572599263/lib/requirejs/require.min.js"></script>
<script type="text/javascript">
//<![CDATA[
require(['core/first'], function() {
;
require.config({ paths: {'jwplayer': 'https://moodle-app2.let.ethz.ch/media/player/jwplayer/jwplayer/jwplayer'}});
require.config({ config: {'media_jwplayer/jwplayer': { licensekey: '2/2Ldn4vIexUjZEkXxuAq940fO4ImfK9Y+p2lXOROeo='}}});
require(["media_videojs/loader"], function(loader) {
    loader.setUp(function(videojs) {
        videojs.options.flash.swf = "https://moodle-app2.let.ethz.ch/media/player/videojs/videojs/video-js.swf";
videojs.addLanguage("en",{
 "Audio Player": "Audio Player",
 "Video Player": "Video Player",
 "Play": "Play",
 "Pause": "Pause",
 "Replay": "Replay",
 "Current Time": "Current Time",
 "Duration Time": "Duration Time",
 "Remaining Time": "Remaining Time",
 "Stream Type": "Stream Type",
 "LIVE": "LIVE",
 "Loaded": "Loaded",
 "Progress": "Progress",
 "Progress Bar": "Progress Bar",
 "progress bar timing: currentTime={1} duration={2}": "{1} of {2}",
 "Fullscreen": "Fullscreen",
 "Non-Fullscreen": "Non-Fullscreen",
 "Mute": "Mute",
 "Unmute": "Unmute",
 "Playback Rate": "Playback Rate",
 "Subtitles": "Subtitles",
 "subtitles off": "subtitles off",
 "Captions": "Captions",
 "captions off": "captions off",
 "Chapters": "Chapters",
 "Descriptions": "Descriptions",
 "descriptions off": "descriptions off",
 "Audio Track": "Audio Track",
 "Volume Level": "Volume Level",
 "You aborted the media playback": "You aborted the media playback",
 "A network error caused the media download to fail part-way.": "A network error caused the media download to fail part-way.",
 "The media could not be loaded, either because the server or network failed or because the format is not supported.": "The media could not be loaded, either because the server or network failed or because the format is not supported.",
 "The media playback was aborted due to a corruption problem or because the media used features your browser did not support.": "The media playback was aborted due to a corruption problem or because the media used features your browser did not support.",
 "No compatible source was found for this media.": "No compatible source was found for this media.",
 "The media is encrypted and we do not have the keys to decrypt it.": "The media is encrypted and we do not have the keys to decrypt it.",
 "Play Video": "Play Video",
 "Close": "Close",
 "Close Modal Dialog": "Close Modal Dialog",
 "Modal Window": "Modal Window",
 "This is a modal window": "This is a modal window",
 "This modal can be closed by pressing the Escape key or activating the close button.": "This modal can be closed by pressing the Escape key or activating the close button.",
 ", opens captions settings dialog": ", opens captions settings dialog",
 ", opens subtitles settings dialog": ", opens subtitles settings dialog",
 ", opens descriptions settings dialog": ", opens descriptions settings dialog",
 ", selected": ", selected",
 "captions settings": "captions settings",
 "subtitles settings": "subititles settings",
 "descriptions settings": "descriptions settings",
 "Text": "Text",
 "White": "White",
 "Black": "Black",
 "Red": "Red",
 "Green": "Green",
 "Blue": "Blue",
 "Yellow": "Yellow",
 "Magenta": "Magenta",
 "Cyan": "Cyan",
 "Background": "Background",
 "Window": "Window",
 "Transparent": "Transparent",
 "Semi-Transparent": "Semi-Transparent",
 "Opaque": "Opaque",
 "Font Size": "Font Size",
 "Text Edge Style": "Text Edge Style",
 "None": "None",
 "Raised": "Raised",
 "Depressed": "Depressed",
 "Uniform": "Uniform",
 "Dropshadow": "Dropshadow",
 "Font Family": "Font Family",
 "Proportional Sans-Serif": "Proportional Sans-Serif",
 "Monospace Sans-Serif": "Monospace Sans-Serif",
 "Proportional Serif": "Proportional Serif",
 "Monospace Serif": "Monospace Serif",
 "Casual": "Casual",
 "Script": "Script",
 "Small Caps": "Small Caps",
 "Reset": "Reset",
 "restore all settings to the default values": "restore all settings to the default values",
 "Done": "Done",
 "Caption Settings Dialog": "Caption Settings Dialog",
 "Beginning of dialog window. Escape will cancel and close the window.": "Beginning of dialog window. Escape will cancel and close the window.",
 "End of dialog window.": "End of dialog window."
});

    });
});;
require(["local_boostnavigation/collapsenavdrawernodes"], function(amd) { amd.init(["mycourses"], []); });;

require(['jquery'], function($) {
    $('#single_select5dbe06c20ed023').change(function() {
        var ignore = $(this).find(':selected').attr('data-ignore');
        if (typeof ignore === typeof undefined) {
            $('#single_select_f5dbe06c20ed022').submit();
        }
    });
});
;
require(["core/search-input"], function(amd) { amd.init("5dbe06c2103a6"); });;

require(['theme_boost/loader']);
require(['theme_boost/drawer'], function(mod) {
    mod.init();
});
;
require(["core/notification"], function(amd) { amd.init(1, []); });;
require(["core/log"], function(amd) { amd.setConfig({"level":"warn"}); });;
require(["core/page_global"], function(amd) { amd.init(); });
});
//]]>
</script>
<script type="text/javascript">
//<![CDATA[
M.str = {"moodle":{"lastmodified":"Last modified","name":"Name","error":"Error","info":"Information","yes":"Yes","no":"No","ok":"OK","cancel":"Cancel","confirm":"Confirm","areyousure":"Are you sure?","closebuttontitle":"Close","unknownerror":"Unknown error"},"repository":{"type":"Type","size":"Size","invalidjson":"Invalid JSON string","nofilesattached":"No files attached","filepicker":"File picker","logout":"Logout","nofilesavailable":"No files available","norepositoriesavailable":"Sorry, none of your current repositories can return files in the required format.","fileexistsdialogheader":"File exists","fileexistsdialog_editor":"A file with that name has already been attached to the text you are editing.","fileexistsdialog_filemanager":"A file with that name has already been attached","renameto":"Rename to \"{$a}\"","referencesexist":"There are {$a} alias\/shortcut files that use this file as their source","select":"Select"},"admin":{"confirmdeletecomments":"You are about to delete comments, are you sure?","confirmation":"Confirmation"}};
//]]>
</script>
<script type="text/javascript">
//<![CDATA[
(function() {Y.use("moodle-filter_glossary-autolinker",function() {M.filter_glossary.init_filter_autolinking({"courseid":0});
});
Y.use("moodle-filter_mathjaxloader-loader",function() {M.filter_mathjaxloader.configure({"mathjaxconfig":"\nMathJax.Hub.Config({\n    config: [\"Accessible.js\", \"Safe.js\"],\n    errorSettings: { message: [\"!\"] },\n    skipStartupTypeset: true,\n    messageStyle: \"none\"\n});\n","lang":"en"});
});
M.util.help_popups.setup(Y);
 M.util.js_pending('random5dbe06c20ed024'); Y.on('domready', function() { M.util.js_complete("init");  M.util.js_complete('random5dbe06c20ed024'); });
})();
//]]>
</script>

                        <div class="tool_usertours-resettourcontainer"></div>
                        <a href="https://download.moodle.org/mobile?version=2018120304.03&amp;lang=en&amp;iosappid=633359593&amp;androidappid=com.moodle.moodlemobile">Get the mobile app</a>
                    </div>
                </footer>            </div>
        </div>
    </div>
    
    <div id="nav-drawer" data-region="drawer" class="d-print-none moodle-has-zindex closed" aria-hidden="true" tabindex="-1">
        <nav class="list-group">
            <a class="list-group-item list-group-item-action " href="https://moodle-app2.let.ethz.ch/" data-key="home" data-isexpandable="0" data-indent="0" data-showdivider="0" data-type="1" data-nodetype="1" data-collapse="0" data-forceopen="1" data-isactive="0" data-hidden="0" data-preceedwithhr="0" >
                <div class="m-l-0">
                    <div class="media">
                        <span class="media-left">
                            <i class="icon fa fa-home fa-fw " aria-hidden="true"  ></i>
                        </span>
                        <span class="media-body ">Home</span>
                    </div>
                </div>
            </a>
        </nav>
    </div>
</div>
<script type="text/javascript" src="https://moodle-app2.let.ethz.ch/theme/boost_ethz/javascript/footer.min.js"></script>
</body>
</html>