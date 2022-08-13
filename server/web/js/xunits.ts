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
          return (us / 1000) + " ms";
       }
       return (us / 1000000) + " s";
    }
    export interface Options {
        container: string,
    }

    export interface TestInfo {
       name: string;
       duration: number;
       status: string;
       total_pass: number;
       total_fail: number;
       total_timeout: number;
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
        readonly testContainer : HTMLDivElement = <HTMLDivElement>document.createElement('div');
        container : HTMLElement | null;
        project   : string = "";

        constructor(options : Options, project: string) {
            this.project = project;
            this.container = document.getElementById(options.container);
            this.container.appendChild(this.testContainer);
            this.getData(null);
	    this.container.addEventListener("click", (event: Event) => {
	       this.onClick(event);
	    });
        }
	onClick(event: Event) {
	   if (event.target instanceof HTMLElement) {
	      var target : HTMLElement = event.target;
	      if (target.className == "group-name") {
	         var parent : HTMLElement = target.closest('.build-xunit-group');
		 if (parent) {
	      	    if (parent.classList.contains("group-visible")) {
		       parent.classList.remove("group-visible");
		    } else {
		       parent.classList.add("group-visible");
		    }
		 }
	      }
	   }
	}
        getData(event : Event) {
            if (this.project) {
                const project : string = this.project;
                const xmlhttp : XMLHttpRequest = new XMLHttpRequest();
                
                xmlhttp.onload = evt => {
                    if (xmlhttp.status == 200 && this.container) {
                        this.updateResult(JSON.parse(xmlhttp.response));
                    }
                };
                xmlhttp.open("GET", "/porion/api/v1/projects/" + project + "/tests");
                xmlhttp.send();
            }
        }
        updateResult(content : TestGroup[]) {
	    var warnCount : number = 0;
	    var infoCount : number = 0;
	    var allCount : number = 0;
	    for (var group of content) {
	       let groupDiv = document.createElement("div");
               groupDiv.className = 'build-xunit-group';
               let groupTestDiv = document.createElement("div");
	       groupTestDiv.className = 'build-xunits';
	       var groupDuration : number = 0;
	       var groupPass : number = 0;
	       var groupFail : number = 0;
	       var groupTimeout : number = 0;
               let build_number : number = 0;
               let divGroup = document.createElement("div");
	       let tests = group.tests;
	       if (tests.length > 1) {
	          divGroup.className = 'build-xunit-group-title';
	       	  for (var test of group.tests) {
                      let divTest = document.createElement("div");
		      divTest.className = 'build-xunit';

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
		     	 link.href = "/porion/builds/view/" + this.project + ":" + test.last_pass_build;
		     	 link.appendChild(document.createTextNode(String(test.last_pass_build)));
		     	 div.appendChild(link);
		      }
		      divTest.appendChild(div);

		      groupTestDiv.appendChild(divTest);
	           }
	       } else {
                   var test = tests[0];
	           divGroup.className = 'build-xunit-group-title build-xunit-group-single';

                   if (test.status == "TEST_PASS") {
		      groupPass++;
		   } else if (test.status == "TEST_FAIL") {
		      groupFail++;
		   } else {
		      groupTimeout++;
		   }
		   groupDuration = groupDuration + test.duration;
	       }

               let div = document.createElement("div");
	       div.textContent = group.name;
	       div.className = 'group-name';
	       divGroup.appendChild(div);

               div = document.createElement("div");
	       div.className = "group-pass";
	       div.textContent = String(groupPass);
	       divGroup.appendChild(div);

               div = document.createElement("div");
	       div.className = "group-fail";
	       div.textContent = String(groupFail);
	       divGroup.appendChild(div);

               div = document.createElement("div");
	       div.className = "group-duration";
	       div.textContent = FormatMicrosecond(groupDuration);
	       divGroup.appendChild(div);

	       div = document.createElement("div");
	       div.className = 'xunit-build';
	       if (build_number > 0) {
	          let link = document.createElement("a");
		  link.href = "/porion/builds/view/" + this.project + ":" + test.last_pass_build;
		  link.appendChild(document.createTextNode(String(test.last_pass_build)));
		  div.appendChild(link);
	       }
	       divGroup.appendChild(div);

               groupDiv.appendChild(divGroup);
	       groupDiv.appendChild(groupTestDiv);
	       this.testContainer.appendChild(groupDiv);
	    }
        }
    }
}

