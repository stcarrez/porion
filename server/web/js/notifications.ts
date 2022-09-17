/*
 *  notifications -- Notifications interface
 *  Copyright (C) 2022 Stephane Carrez
 *  Written by Stephane Carrez (Stephane.Carrez@gmail.com)
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
namespace Porion {

    /* Options to control the Xunit renderer */
    export interface Options {
        container: string,
	    projectSelector: string,
    }

    export class Notifications {
        projectSelector : HTMLElement | null;
        container : HTMLElement | null;

        constructor(options : Options, project: string) {
            this.container = document.getElementById(options.container);
            this.projectSelector = document.getElementById(options.projectSelector);
	        if (this.projectSelector) {
	            this.projectSelector.addEventListener("change", (event: Event) => {
	                this.onSelectProject(event);
	            });
	        }
        }
	    onSelectProject(event: Event) {
            const xmlhttp : XMLHttpRequest = new XMLHttpRequest();
            const selector : HTMLSelectElement | null = <HTMLSelectElement> event.target;
            if (!selector) {
                return;
            }

            xmlhttp.onload = evt => {
                if (xmlhttp.status == 200 && this.container) {
                    
                }
            }
            xmlhttp.open("POST", "/porion/api/v1/subscribers");
	        xmlhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
            xmlhttp.send("project=" + selector.value);
	    }
    }
}

