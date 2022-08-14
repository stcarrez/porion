/*
 *  xunits -- Display unit tests for a project
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
    function FormatMicrosecond(us : number) : string {
       if (us < 1000) {
          return us + " us";
       }
       if (us < 1000000) {
          us = us / 1000;
          return us.toFixed(3) + " ms";
       }
       us = us / 1000000;
       return us.toFixed(3) + " s";
    }

    /* Options to control the Xunit renderer */
    export interface Options {
        container: string,
        project: string | null,
	build: string | null
    }

    /* JSON to describe a build test result */
    export interface BuildTestInfo {
       name: string;
       duration: number;
       status: string;
       total_pass: number;
       total_fail: number;
       total_timeout: number;
    }

    /* JSON to describe the project wide test info */
    export interface TestInfo extends BuildTestInfo {
       total_skip: number;
       last_pass_build: number | null;
       last_fail_build: number | null;
       last_timeout_build: number | null;
       last_skip_build: number | null;
    }
    export interface TestGroup {
       name : string;
       tests: TestInfo[];
    }
    export class ProjectTests {
        testContainer : HTMLElement | null;
        project   : string | null;
	build     : string | null;

        constructor(options : Options, project: string) {
            this.project = options.project;
	    this.build = options.build;
            this.testContainer = document.getElementById(options.container);
	    if (this.testContainer) {
	       this.testContainer.addEventListener("click", (event: Event) => {
	          this.onClick(event);
	       });
               this.getData(null);
	    }
        }
	onClick(event: Event) {
	   if (event.target instanceof HTMLElement) {
	      const target : HTMLElement = event.target;
	      if (target.className == "xunit-group-name") {
	         const parent : HTMLElement = target.closest('.xunit-group');
		 if (parent) {
	      	    if (parent.classList.contains("xunit-group-visible")) {
		       parent.classList.remove("xunit-group-visible");
		    } else {
		       parent.classList.add("xunit-group-visible");
		    }
		 }
	      }
	   }
	}
        getData(event : Event) {
            if (this.project || this.build) {
                const project : string = this.project;
                const xmlhttp : XMLHttpRequest = new XMLHttpRequest();
                
                xmlhttp.onload = evt => {
                    if (xmlhttp.status == 200 && this.testContainer) {
                        this.updateResult(JSON.parse(xmlhttp.response));
                    }
                }
		let uri : string;
		if (this.project) {
		   uri = "/porion/api/v1/projects/" + this.project + "/tests";
		} else {
		   uri = "/porion/api/v1/builds/" + this.build + "/tests";
		}
                xmlhttp.open("GET", uri);
                xmlhttp.send();
            }
        }
        createInfo(title : string, pass : number, fail : number, duration: number) : HTMLDivElement {
            const divGroup : HTMLDivElement = document.createElement("div");
            divGroup.className = 'xunit-group-title';

            let div : HTMLDivElement = document.createElement("div");
	    div.textContent = title;
	    div.className = 'xunit-group-name';
	    divGroup.appendChild(div);

            div = document.createElement("div");
	    div.className = "xunit-pass";
	    div.textContent = String(pass);
	    divGroup.appendChild(div);

            div = document.createElement("div");
	    div.className = "xunit-fail";
	    div.textContent = String(fail);
	    divGroup.appendChild(div);

            div = document.createElement("div");
	    div.className = "xunit-duration";
	    div.textContent = FormatMicrosecond(duration);
	    divGroup.appendChild(div);

            return divGroup;
	}
        updateResult(content : TestGroup[]) {
	    let warnCount : number = 0;
	    let infoCount : number = 0;
	    let allCount : number = 0;
	    let totPass : number = 0;
	    let totFail : number = 0;
	    let totDuration : number = 0;
	    const totDiv = document.createElement("div");
	    totDiv.className = 'xunit-total';
	    this.testContainer.appendChild(totDiv);

	    for (let group of content) {
	       let groupDiv = document.createElement("div");
               groupDiv.className = 'xunit-group';
	       let groupDuration : number = 0;
	       let groupPass : number = 0;
	       let groupFail : number = 0;
	       let groupTimeout : number = 0;
               let build_number : number = 0;
	       let tests = group.tests;
	       let groupTestDiv : HTMLDivElement | null;
	       if (tests.length > 1) {
	          groupTestDiv = document.createElement("div");
	       	  groupTestDiv.className = 'xunits';
	       	  for (let test of group.tests) {
                      let divTest = document.createElement("div");
		      divTest.className = 'xunit';

                      if (test.status == "TEST_PASS") {
		         groupPass++;
		      } else if (test.status == "TEST_FAIL") {
		         groupFail++;
		      } else {
		         groupTimeout++;
		      }
		      groupDuration = groupDuration + test.duration;

		      let div = document.createElement("div");
		      div.textContent = test.name;
		      div.className = 'xunit-name';
		      divTest.appendChild(div);
		  
		      div = document.createElement("div");
		      div.textContent = FormatMicrosecond(test.duration);
		      div.className = 'xunit-duration';
		      divTest.appendChild(div);

		      div = document.createElement("div");
		      div.className = 'xunit-build';
		      if (test.last_pass_build) {
		         if (test.last_pass_build > build_number) {
			    build_number = test.last_pass_build;
			 }
		         let link = document.createElement("a");
		     	 link.href = "/porion/builds/view/" + this.project + ":" + test.last_pass_build + "/summary";
		     	 link.appendChild(document.createTextNode(String(test.last_pass_build)));
		     	 div.appendChild(link);
		      }
		      divTest.appendChild(div);

		      groupTestDiv.appendChild(divTest);
	           }
	       } else {
                   let test = tests[0];

                   if (test.status == "TEST_PASS") {
		      groupPass++;
		   } else if (test.status == "TEST_FAIL") {
		      groupFail++;
		   } else {
		      groupTimeout++;
		   }
		   groupDuration = groupDuration + test.duration;
	           if (test.last_pass_build) {
                      build_number = test.last_pass_build;
		   }
	       }

               totPass += groupPass;
	       totFail += groupFail;
	       totDuration += groupDuration;

               const divGroup = this.createInfo(group.name, groupPass, groupFail, groupDuration);
	       if (tests.length > 1) {
	           divGroup.className = 'xunit-group-title';
	       } else {
	           divGroup.className = 'xunit-group-title xunit-group-single';
	       }

	       let div = document.createElement("div");
	       div.className = 'xunit-build';
	       if (build_number > 0) {
	          let link = document.createElement("a");
		  link.href = "/porion/builds/view/" + this.project + ":" + build_number + "/summary";
		  link.appendChild(document.createTextNode(String(build_number)));
		  div.appendChild(link);
	       }
	       divGroup.appendChild(div);

               groupDiv.appendChild(divGroup);
	       if (groupTestDiv) {
	          groupDiv.appendChild(groupTestDiv);
	       }
	       this.testContainer.appendChild(groupDiv);
	    }

            const divGroup = this.createInfo("Total", totPass, totFail, totDuration);
	    divGroup.className = 'xunit-group-title xunit-group-single';
            totDiv.appendChild(divGroup);
        }
    }
}

