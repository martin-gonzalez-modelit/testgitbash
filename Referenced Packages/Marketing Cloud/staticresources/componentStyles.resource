.tooltip-component {
    color: #ccc!important;
    margin-left: 10px
}

.tooltip-inner {
    background-color: #0070D2!important;
}

.tooltip-arrow {
    border-top-color: #0070D2!important;
}

.tooltip-xjq {
    position: relative;
    display: inline-block;
}

.tooltip-xjq .tooltiptext-xjq {
    font-family: Salesforce Sans, Proxima Nova, Arial, Sans-serif;
    font-size: 12px;
    line-height: 1.4;
    visibility: hidden;
    width: 190px;
    background-color: #0070D2;
    color: #fff;
    text-align: center;
    border-radius: 6px;
    padding: 5px 5px;
    position: absolute;
    z-index: 1;
    bottom: 125%;
    left: 50%;
    margin-left: -90px;
    opacity: 0;
    transition: opacity 1s;
}

.tooltip-xjq .tooltiptext-xjq::after {
    content: "";
    position: absolute;
    top: 100%;
    left: 50%;
    margin-left: -5px;
    border-width: 5px;
    border-style: solid;
    border-color: #0070D2 transparent transparent transparent;
}

.tooltip-xjq:hover .tooltiptext-xjq {
    visibility: visible;
    opacity: .90;
}

.mainSpinner-component {
    position: absolute;
    height: 100px;
    width: 100px;
    top: 50%;
    left: 50%;
    margin-left: -50px;
    margin-top: -50px;
}

.uiInputDefaultError {
    position: absolute;
    float: left;
    top: 14px;
    width: 300px;
    height: 0px;
}

/* Absolute Center Spinner */
.loadingMC {
    position: fixed;
    z-index: 999;
    height: 2em;
    width: 2em;
    overflow: show;
    margin: auto;
    top: 0;
    left: 0;
    bottom: 0;
    right: 0;
}

/* Transparent Overlay */
.loadingMC:before {
    content: '';
    display: block;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(0, 0, 0, 0.3);
}

/*Modal Styling*/
.modal-dialog1 {
    width: 500px; 
    height: 450px;
    color: #16325C;
    position: fixed;
    top: 50%;
    left: 50%;
    margin-top: -225px;
    margin-left: -225px;
}
.modal1 {
    display: block; 
    position: fixed; /* Stay in place */
    z-index: 100; /* Sit on top */
    left: 0;
    top: 0;
    width: 100%; /* Full width */
    height: 100%; /* Full height */
    overflow: auto; /* Enable scroll if needed */
    background-color: rgb(0,0,0); /* Fallback color */
    background-color: rgba(0,0,0,0.4); /* Black w/ opacity */
}
.modal-content1 {
    border: none;
    color: #16325C;
    border-radius: 4px;
    height: 360px;
    position: relative;
    background-color: #fefefe;
    margin: auto;
    border: 1px solid #888;
    width: 410px;
    box-shadow: 0 4px 8px 0 rgba(0,0,0,0.2),0 6px 20px 0 rgba(0,0,0,0.19);     
}

.modal-header1 {
  font-size: 24px;
    border-bottom: 2px solid #D8DDE6;
    min-height: 16.4px;
    text-align: center;
    padding: 15px;
}

.modal-body1 {
    height: calc(100% - 90px);
    overflow-y: auto;
    padding: 15px;
}
.modal-body1 p {
    font-size: 14px;
    text-align: left;
    vertical-align: bottom;
    display: table-cell;
}

.modal-footer1 {
    font-size: 14px;
    text-align: right;
    border-top: 2px solid #D8DDE6;
    background: #F4F6F9;
    border-bottom-left-radius: 4px;
    border-bottom-right-radius: 4px;
    padding: 15px;
}

.modal-footer1 p {
  margin-top:8px;
    color: #d8dde6;
}

.modal2 { 
	display: block;
    position: fixed; /* Stay in place */
    z-index: 100; /* Sit on top */
    left: 0;
    top: 0;
    width: 100%; /* Full width */
    height: 100%; /* Full height */
    overflow: auto; /* Enable scroll if needed */
    background-color: rgb(0,0,0); /* Fallback color */
    background-color: rgba(0,0,0,0.4); /* Black w/ opacity */
}

.modal2 .hide {
	display: none;
}

.modal-dialog2 {
    width: 500px; 
    color: #16325C;
    position: fixed;
    top: 50%;
    left: 50%;
    margin-top: -225px;
    margin-left: -225px;
}

.modal-content2 {
    border: none;
    color: #16325C;
    border-radius: 4px;
    position: relative;
    background-color: #fefefe;
    margin: auto;
    border: 1px solid #888;
    width: 410px;
    box-shadow: 0 4px 8px 0 rgba(0,0,0,0.2),0 6px 20px 0 rgba(0,0,0,0.19); 
}

.modal-header2 {
    font-size: 24px;
    border-bottom: 2px solid #D8DDE6;
    min-height: 16.4px;
    text-align: center;
    padding: 15px;
}

.modal-body2 {
  max-height: 225px;
    overflow-y: auto;
    padding: 15px;
}
.modal-body2 p {
    font-size: 14px;
    text-align: left;
    vertical-align: bottom;
    display: table-cell;
}

.modal-footer2 {
    font-size: 14px;
    text-align: right;
    border-top: 2px solid #D8DDE6;
    background: #F4F6F9;
    border-bottom-left-radius: 4px;
    border-bottom-right-radius: 4px;
    padding: 15px;
    height: 100%;
}