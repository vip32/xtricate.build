configuration `
    -settings {
        setting "username" "userX"
        setting "google_url" "http://www.google.com"
        dynamicsetting "dynamiccount" { 1..5 }
        dynamicsetting "Password" { GeneratePassword }
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
                dynamicsetting "dynamiccount2" { 5..9 } 
            } `
            -nodes {
                #loadbalancer "lb1" "internetloadbalancer" `
                #    -url "www.xportalmvc.com" `
                #    -skipinstall -skipuninstall
                                
                computer "webserver" `
                    -name @("PC*","BDS*") -ip "127.0.0.1" -domain "localhost" `
                    -description "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod 
                        tempor invidunt ut labore et dolore magna aliquyam erat." `
                    -resources {
                        remoting -id "remoting" -localdirectory "c:\releases" `
                            -identityref "administrator" `
                            -tags "all"

                        certificate "websslcert" "web ssl certificate" `
                            -path ".\assets\demo_local.pfx" -password "password" `
                            -thumbprint "9061152f2ecd0dcd1cf5bd2bce2219a5da113469" -tags "all"

                        apppool "defaultapppool" "DefaultAppPool" `
                            -skipinstall -skipuninstall -tags "all"

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
                    } `
                    -packages {
                        databasepackage "demo.app" "demo console app" `
                            -path "..\src\demo.app" `
                            -tags "all" 
                            
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
}