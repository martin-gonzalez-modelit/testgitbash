/* Integrated Users */
div.integratedUsersBlock div {
	float: left;
}

div[id*=selectedUsersButtons] {
	margin-top: 40px;
	text-align: center;
}

[id*=integratedUsersSelector] select {
	width: 150px;
}

/* Tabs */
.rich-tab-active {
	background: #F1F1F1;
}

.rich-tab-inactive {
	background: #DEDEDE;
}

/* Popups and hideable DIVs */
.popupBlocker {
	display: block;
	position: absolute;
	width: 100%;
	height: 100%;
	background: none;
}

.popupBlockerHidden {
	display: none;
}

.popup {
	position: absolute;
	display: block;
	overflow: auto;
	width: 450px;
	max-height: 300px;
	margin: 0;
	padding: 0;
	background-color: #fff;
	border: 2px #ccc solid;
}

.popup .detailList td {
	width: 100% !important;
	text-align: left;
	font-size: 12px;
}

.orangebutton {
	background-color: #E28C05;
	color: white;
	background-image:none;
}

.hide {
	display: none;
}

.show {
	display: block;
}

.spinnerLarge {
	display: inline;
	width: 100px;
}

.spinnerSmall {
	display: inline;
	width: 20px;
	padding: 0 10px 0 10px;
}

/* Send Email */
[id*=emailSubject] {
	width: 300px;
}

div[id*=audienceSection] label {
	margin-left: -6px;
}

div.emailFolder {
	padding-left: 10px;
}

div.closed {
	display: block;
}

div.open {
	display: block;
}

div.emailFolder {
	padding-left: 10px;
}

/* Business Units Console */
[id*=businessUnitsBlock] {
	width: 80%;
}

.buItem {
	float: left;
	width: 200px;
	margin-right: 30px;
}

div.clear {
	clear: both;
}

/* Dashboard table */
tr.even {
	background-color: #eee;
}

/* Error display */
.errors * {
	color: #600;
	font-weight: bold;
}

.errors ul {
	list-style: none;
	margin: 0;
	padding: 0;
}

.errors input {
	border: 2px #600 solid;
}

.unavailable-feature {
	color: #999;
	font-style: italic;
}cl