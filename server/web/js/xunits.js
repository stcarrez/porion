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
var Porion;
(function (Porion) {
    function FormatMicrosecond(us) {
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
    var ProjectTests = /** @class */ (function () {
        function ProjectTests(options, project) {
            var _this = this;
            this.project = options.project;
            this.build = options.build;
            this.testContainer = document.getElementById(options.container);
            if (this.testContainer) {
                this.testContainer.addEventListener("click", function (event) {
                    _this.onClick(event);
                });
                this.getData(null);
            }
        }
        ProjectTests.prototype.onClick = function (event) {
            if (event.target instanceof HTMLElement) {
                var target = event.target;
                if (target.className == "xunit-group-name") {
                    var parent_1 = target.closest('.xunit-group');
                    if (parent_1) {
                        if (parent_1.classList.contains("xunit-group-visible")) {
                            parent_1.classList.remove("xunit-group-visible");
                        }
                        else {
                            parent_1.classList.add("xunit-group-visible");
                        }
                    }
                }
            }
        };
        ProjectTests.prototype.getData = function (event) {
            var _this = this;
            if (this.project || this.build) {
                var project = this.project;
                var xmlhttp_1 = new XMLHttpRequest();
                xmlhttp_1.onload = function (evt) {
                    if (xmlhttp_1.status == 200 && _this.testContainer) {
                        _this.updateResult(JSON.parse(xmlhttp_1.response));
                    }
                };
                var uri = void 0;
                if (this.project) {
                    uri = "/porion/api/v1/projects/" + this.project + "/tests";
                }
                else {
                    uri = "/porion/api/v1/builds/" + this.build + "/tests";
                }
                xmlhttp_1.open("GET", uri);
                xmlhttp_1.send();
            }
        };
        ProjectTests.prototype.createInfo = function (title, pass, fail, duration) {
            var divGroup = document.createElement("div");
            divGroup.className = 'xunit-group-title';
            var div = document.createElement("div");
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
        };
        ProjectTests.prototype.updateResult = function (content) {
            var warnCount = 0;
            var infoCount = 0;
            var allCount = 0;
            var totPass = 0;
            var totFail = 0;
            var totDuration = 0;
            var totDiv = document.createElement("div");
            totDiv.className = 'xunit-total';
            this.testContainer.appendChild(totDiv);
            for (var _i = 0, content_1 = content; _i < content_1.length; _i++) {
                var group = content_1[_i];
                var groupDiv = document.createElement("div");
                groupDiv.className = 'xunit-group';
                var groupDuration = 0;
                var groupPass = 0;
                var groupFail = 0;
                var groupTimeout = 0;
                var build_number = 0;
                var tests = group.tests;
                var groupTestDiv = void 0;
                if (tests.length > 1) {
                    groupTestDiv = document.createElement("div");
                    groupTestDiv.className = 'xunits';
                    for (var _a = 0, _b = group.tests; _a < _b.length; _a++) {
                        var test = _b[_a];
                        var divTest = document.createElement("div");
                        divTest.className = 'xunit';
                        if (test.status == "TEST_PASS") {
                            groupPass++;
                        }
                        else if (test.status == "TEST_FAIL") {
                            groupFail++;
                        }
                        else {
                            groupTimeout++;
                        }
                        groupDuration = groupDuration + test.duration;
                        var div_1 = document.createElement("div");
                        div_1.textContent = test.name;
                        div_1.className = 'xunit-name';
                        divTest.appendChild(div_1);
                        div_1 = document.createElement("div");
                        div_1.textContent = FormatMicrosecond(test.duration);
                        div_1.className = 'xunit-duration';
                        divTest.appendChild(div_1);
                        div_1 = document.createElement("div");
                        div_1.className = 'xunit-build';
                        if (test.last_pass_build) {
                            if (test.last_pass_build > build_number) {
                                build_number = test.last_pass_build;
                            }
                            var link = document.createElement("a");
                            link.href = "/porion/builds/view/" + this.project + ":" + test.last_pass_build + "/summary";
                            link.appendChild(document.createTextNode(String(test.last_pass_build)));
                            div_1.appendChild(link);
                        }
                        divTest.appendChild(div_1);
                        groupTestDiv.appendChild(divTest);
                    }
                }
                else {
                    var test = tests[0];
                    if (test.status == "TEST_PASS") {
                        groupPass++;
                    }
                    else if (test.status == "TEST_FAIL") {
                        groupFail++;
                    }
                    else {
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
                var divGroup_1 = this.createInfo(group.name, groupPass, groupFail, groupDuration);
                if (tests.length > 1) {
                    divGroup_1.className = 'xunit-group-title';
                }
                else {
                    divGroup_1.className = 'xunit-group-title xunit-group-single';
                }
                var div = document.createElement("div");
                div.className = 'xunit-build';
                if (build_number > 0) {
                    var link = document.createElement("a");
                    link.href = "/porion/builds/view/" + this.project + ":" + build_number + "/summary";
                    link.appendChild(document.createTextNode(String(build_number)));
                    div.appendChild(link);
                }
                divGroup_1.appendChild(div);
                groupDiv.appendChild(divGroup_1);
                if (groupTestDiv) {
                    groupDiv.appendChild(groupTestDiv);
                }
                this.testContainer.appendChild(groupDiv);
            }
            var divGroup = this.createInfo("Total", totPass, totFail, totDuration);
            divGroup.className = 'xunit-group-title xunit-group-single';
            totDiv.appendChild(divGroup);
        };
        return ProjectTests;
    }());
    Porion.ProjectTests = ProjectTests;
})(Porion || (Porion = {}));
