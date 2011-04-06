configuration `
    -settings {
        setting "worldtimeserverurl" "http://www.worldtimeserver.com"
        dynamicsetting "setting3" { GeneratePassword }
    } `
    -environments { 
        environment "local" `
            -name "local development environment" `
            -description "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod 
                tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam 
                et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.
                * installation manual
                ** read it
                ** again
                * follow the instructions
                * test the installation
                ** systemtests" `
            -settings { 
                setting "debug" "true"
                setting "setting1" "localappsettingvalue"
                dynamicsetting "setting2" { 1..5 } 
            } `
            -nodes {
                #loadbalancer "lb1" "internetloadbalancer" `
                #    -url "www.xportalmvc.com" `
                #    -skipinstall -skipuninstall
                node "internet" `
                    -name "somewhereoutthere"
                    
                computer "webserver" `
                    -name @("PC*","BDS*") -ip "127.0.0.1" -domain "localhost" `
                    -description "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod 
                        tempor invidunt ut labore et dolore magna aliquyam erat." `
                    -resources {
                        remoting -id "remoting" -localdirectory "c:\releases" `
                            -identityref "remoteadmin" `
                            -tags "all"

                        certificate "websslcert" "web ssl certificate" `
                            -path ".\assets\demo_local.pfx" -password "password" `
                            -thumbprint "9061152f2ecd0dcd1cf5bd2bce2219a5da113469" -tags "all"

                        apppool "defaultapppool" "DefaultAppPool" `
                            -skipinstall -skipuninstall -tags "all"

                        localidentity "remoteadmin" "remoteadmin" `
                            -password "Password123" `
                            -tags "all"

                        localidentity "networkservice" "networkservice" `
                            -skipinstall -skipuninstall -tags "all"
                                        
                        #website "defaultwebsite" "default web site" `
						#	-path "c:\inetpub\wwwroot" `
                        #    -apppoolref "defaultapppool" `
                        #    -hostheader "localhost" `
                        #    -skipinstall -skipuninstall -tags "all", "sites"
                        website "demosite" "xtricate.build demo web site" `
							-path "c:\inetpub\wwwroot" `
                            -apppoolref "defaultapppool" `
                            -hostheader "www.demosite.local" `
                            -certificateref "websslcert" `
                            -settings { setting "demosetting" "local" } `
                             -tags "all", "sites"
                             
                        hostsfile "demohost" "local host file" {
                                hostsfilewebsite "demosite" "demo site host entry comment"
                                hostsfilecustom "routerhostname" "192.168.1.1" "demo router host entry comment"
                        } -tags "all"
                    } `
                    -packages {
                        genericpackage "demo.app" "demo console app" `
                            -path "..\src\demo.app" `
                            -skipinstallcopy -tags "all" 
                            
						databasepackage "demo.db" "demodatabase1_local.sdf" `
                            -description "demo database for local environment" `
                            -path "..\src\demo.db" `
                            -skipinstallcopy -tags "all" 
                            
                        webapppackage "demo.webapp" "demo web application" `
                            -path "..\src\demo.webapp" `
                            -websiteref "demosite" `
                            -virtualdir "webapp" -isapplication `
                            -settings { 
                                dynamicsetting "packagesettingdynamic2" { CurrentDate }
                            } `
                            -skipinstallcopy -tags "all", "sites"
                        
                        systemtestpackage "demo.integrationtests" "demo integration tests" `
							-skipinstallcopy -tags "all"
                        
                        systemtestpackage "demo.webapp.specs" "demo web application specflow tests" `
							-skipinstallcopy -tags "all"
                            
                        webapppackage "demo.webservices" "demo web services" `
                            -path "..\src\demo.webservices" `
                            -websiteref "demosite" `
                            -virtualdir "webservices" -isapplication `
                            -skipinstallcopy -tags "all", "sites"
                    }
            }
		environment "test" `
            -name "test development environment" `
            -description "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod 
                tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam 
                et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.
                * installation manual
                ** read it
                ** again
                * follow the instructions
                * test the installation
                ** systemtests" `
            -settings { 
                setting "debug" "false"
                setting "setting1" "testappsettingvalue"
                dynamicsetting "setting2" { 1..15 } 
            } `
            -nodes {
                #loadbalancer "lb1" "internetloadbalancer" `
                #    -url "www.xportalmvc.com" `
                #    -skipinstall -skipuninstall
                node "internet" `
                    -name "somewhereoutthere"
                    
                computer "webserver" `
                    -name "DEV-SRV*" -ip "127.0.0.1" -domain "localhost" `
                    -description "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod 
                        tempor invidunt ut labore et dolore magna aliquyam erat." `
                    -resources {
                        remoting -id "remoting" -localdirectory "c:\releases" `
                            -identityref "remoteadmin" `
                            -tags "all"

                        certificate "websslcert" "web ssl certificate" `
                            -path ".\assets\demo_test.pfx" -password "password" `
                            -thumbprint "9061152f2ecd0dcd1cf5bd2bce2219a5da113469" -tags "all"

                        apppool "defaultapppool" "DefaultAppPool" `
                            -skipinstall -skipuninstall -tags "all"

                        localidentity "remoteadmin" "remoteadmin" `
                            -password "Password123" `
                            -tags "all"

                        localidentity "networkservice" "networkservice" `
                            -skipinstall -skipuninstall -tags "all"
                                        
                        #website "defaultwebsite" "default web site" `
						#	-path "c:\inetpub\wwwroot" `
                        #    -apppoolref "defaultapppool" `
                        #    -hostheader "localhost" `
                        #    -skipinstall -skipuninstall -tags "all", "sites"
                        website "demosite" "xtricate.build demo web site" `
							-path "c:\inetpub\wwwroot" `
                            -apppoolref "defaultapppool" `
                            -hostheader "www.demosite.test" `
                            -certificateref "websslcert" `
                            -settings { setting "demosetting" "test" } `
                            -tags "all", "sites"
                             
                        hostsfile "demohost" "local host file" {
                                hostsfilewebsite "demosite" "demo site host entry comment"
                                hostsfilecustom "routerhostname" "192.168.1.1" "demo router host entry comment"
                        } -tags "all"
                    } `
                    -packages {
                        genericpackage "demo.app" "demo console app" `
                            -path "c:\demo\demo.app" `
                            -tags "all" 
                            
						databasepackage "demo.db" "demodatabase1_test.sdf" `
                            -description "demo database for test environment" `
                            -path "c:\demo\demo.db" `
                            -tags "all" 
                            
                        webapppackage "demo.webapp" "demo web application" `
                            -path "c:\demo\demo.webapp" `
                            -websiteref "demosite" `
                            -virtualdir "webapp" -isapplication `
                            -settings { 
                                dynamicsetting "packagesettingdynamic2" { CurrentDate }
                            } `
                            -tags "all", "sites"
                        
                        systemtestpackage "demo.integrationtests" "demo integration tests" `
							-tags "all"
                        
                        systemtestpackage "demo.webapp.specs" "demo web application specflow tests" `
							-skipinstallcopy -tags "all"
                            
                        webapppackage "demo.webservices" "demo web services" `
                            -path "c:\demo\demo.webservices" `
                            -websiteref "demosite" `
                            -virtualdir "webservices" -isapplication `
                            -tags "all", "sites"
                    }
            }
}