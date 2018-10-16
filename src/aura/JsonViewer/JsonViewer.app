<aura:application controller="ApplicationFileController">

    <ltng:require styles="/resource/xml2json/bootstrap.css,/resource/xml2json/font-awesome.css,
/resource/xml2json/prettify.css,/resource/xml2json/layout.css,/resource/xml2json/json.css,/resource/xml2json/style.css"/>
    <ltng:require scripts="/resource/xml2json/jquery.js,/resource/xml2json/bootstrap.js,
/resource/xml2json/json-to-html.js,/resource/xml2json/jquery-json-to-html.js,/resource/xml2json/json.js" />

    <aura:attribute name="appFileId" type="String" default="" />
    <aura:handler name="init" value="{!this}" action="{!c.doInit}" />

    <div id="main">
        <h1>JSON Viewer</h1>
        <p/>

        <p>Application File ID: {!v.appFileId}</p>

        <div class='divider'></div>
        <div id='top'></div>
        <p/>
    </div>

</aura:application>