/*
 *  wi2wic -- Wiki To Wiki Converter
 *  Copyright (C) 2020 Stephane Carrez
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
            return (us / 1000) + " ms";
        }
        return (us / 1000000) + " s";
    }
    var ProjectTests = /** @class */ (function () {
        function ProjectTests(options, project) {
            var _this = this;
            this.testContainer = document.createElement('div');
            this.project = "";
            this.project = project;
            this.container = document.getElementById(options.container);
            this.container.appendChild(this.testContainer);
            this.showAll = document.getElementById(options.btnShowAll);
            this.showInfo = document.getElementById(options.btnShowInfo);
            this.showWarn = document.getElementById(options.btnShowWarning);
            this.countAll = document.getElementById(options.countAll);
            this.countInfo = document.getElementById(options.countInfo);
            this.countWarn = document.getElementById(options.countWarn);
            this.getData(null);
            this.container.addEventListener("click", function (event) {
                _this.onClick(event);
            });
            if (this.showAll) {
                this.showAll.addEventListener("click", function (event) {
                    _this.setMode(event, 'build-show-all');
                });
            }
            if (this.showInfo) {
                this.showInfo.addEventListener("click", function (event) {
                    _this.setMode(event, 'build-show-info');
                });
            }
            if (this.showWarn) {
                this.showWarn.addEventListener("click", function (event) {
                    _this.setMode(event, 'build-show-warning');
                });
            }
        }
        ProjectTests.prototype.onClick = function (event) {
            if (event.target instanceof HTMLElement) {
                var target = event.target;
                if (target.className == "group-name") {
                    var parent = target.closest('.build-test-group');
                    if (parent) {
                        if (parent.classList.contains("group-visible")) {
                            parent.classList.remove("group-visible");
                        }
                        else {
                            parent.classList.add("group-visible");
                        }
                    }
                }
            }
        };
        ProjectTests.prototype.getData = function (event) {
            var _this = this;
            if (this.project) {
                var project = this.project;
                var xmlhttp_1 = new XMLHttpRequest();
                xmlhttp_1.onload = function (evt) {
                    if (xmlhttp_1.status == 200 && _this.container) {
                        _this.updateResult(JSON.parse(xmlhttp_1.response));
                    }
                };
                xmlhttp_1.open("GET", "/porion/api/v1/projects/" + project + "/tests");
                xmlhttp_1.send();
            }
        };
        ProjectTests.prototype.updateResult = function (content) {
            var warnCount = 0;
            var infoCount = 0;
            var allCount = 0;
            for (var _i = 0, content_1 = content; _i < content_1.length; _i++) {
                var group = content_1[_i];
                var groupDiv = document.createElement("div");
                groupDiv.className = 'build-test-group';
                var groupTestDiv = document.createElement("div");
                groupTestDiv.className = 'build-tests';
                var groupDuration = 0;
                var groupPass = 0;
                var groupFail = 0;
                var groupTimeout = 0;
                for (var _a = 0, _b = group.tests; _a < _b.length; _a++) {
                    var test = _b[_a];
                    var divTest = document.createElement("div");
                    divTest.className = 'build-test';
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
                    div_1.className = 'test-name';
                    divTest.appendChild(div_1);
                    div_1 = document.createElement("div");
                    div_1.textContent = FormatMicrosecond(test.duration);
                    div_1.className = 'test-duration';
                    divTest.appendChild(div_1);
                    div_1 = document.createElement("div");
                    div_1.className = 'test-build';
                    if (test.last_pass_build) {
                        var link = document.createElement("a");
                        link.href = "/porion/builds/view/" + this.project + ":" + test.last_pass_build;
                        link.appendChild(document.createTextNode(String(test.last_pass_build)));
                        div_1.appendChild(link);
                    }
                    divTest.appendChild(div_1);
                    groupTestDiv.appendChild(divTest);
                }
                var divGroup = document.createElement("div");
                divGroup.className = 'build-test-group-title';
                var div = document.createElement("div");
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
                groupDiv.appendChild(divGroup);
                groupDiv.appendChild(groupTestDiv);
                this.testContainer.appendChild(groupDiv);
            }
        };
        ProjectTests.prototype.setMode = function (event, mode) {
            this.container.classList.remove('build-show-all', 'build-show-info', 'build-show-warning');
            this.container.classList.add(mode);
        };
        return ProjectTests;
    }());
    Porion.ProjectTests = ProjectTests;
})(Porion || (Porion = {}));
