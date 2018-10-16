({
    previousPage : function(component) {
        let myEvent = $A.get("e.c:PaginatorPageChangeEvt");

        myEvent.setParams({ "direction": "previous"});
        myEvent.fire();
    },

    nextPage : function(component) {
        let myEvent = $A.get("e.c:PaginatorPageChangeEvt");

        myEvent.setParams({ "direction": "next"});
        myEvent.fire();
    }
})