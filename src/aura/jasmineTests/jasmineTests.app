<aura:application >
<!--
    <c:lts_jasmineRunner testFiles="{!join(',', 
        $Resource.jasmineHelloWorldTests,
        $Resource.jasmineExampleTests,
        $Resource.jasmineLightningDataServiceTests,
        $Resource.jasmineACQCApplicationSearch
    )}" />
-->
    <c:lts_jasmineRunner testFiles="{!join(',',
        $Resource.jasmineFieldQCWizardTests,
        $Resource.jasmineACQCApplicationSearch
    )}" />

</aura:application>