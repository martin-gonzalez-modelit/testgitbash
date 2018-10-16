/* Manual tooltips */
.tooltip-text {
	visibility: hidden;
	opacity: 0;
    text-decoration: none;
    position: absolute;
    width: 15em;
    z-index: 1;
    background-color: #fefdb9;
    padding: 2px 5px;
    border: 1px solid orange;
    text-align: left;
    white-space: normal;
    font-family: Arial,Helvetica,sans-serif;
    font-weight: normal;
    font-size: 90%;
    color: #000;
}

.tooltip-left {
	right: 101%;
}

.tooltip-right {
	left: 5%;
}

.tooltip-below {
	top: 105%;
}

.tooltip-above {
	bottom: 105%;
}

.tooltip:hover .tooltip-text {
	visibility: visible;
    opacity: 0.99;
}

.tooltip .helpOrb {
	background-position: top left;
}

.tooltip:hover .helpOrb {
	background-position: top right;
}
