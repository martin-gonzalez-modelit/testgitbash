/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class RollupActionCalculate {
    global RollupActionCalculate() {

    }
    @InvocableMethod(label='Calculates a rollup' description='Provide the Id of the parent record and the unique name of the rollup to calculate, you specificy the same Id multiple times to invoke multiple rollups')
    global static void calculate(List<dlrs.RollupActionCalculate.RollupToCalculate> rollupsToCalculate) {

    }
global class RollupToCalculate {
    @InvocableVariable(label='Parent Record Id' required=true)
    global Id ParentId;
    @InvocableVariable(label='Rollup Summary Unique Name' required=true)
    global String RollupSummaryUniqueName;
    global RollupToCalculate() {

    }
}
}
