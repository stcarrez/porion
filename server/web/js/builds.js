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
    var BuildLog = /** @class */ (function () {
        function BuildLog(options, build) {
            var _this = this;
            this.logContainer = document.createElement('div');
            this.build = "";
            this.build = build;
            this.container = document.getElementById(options.container);
            this.container.appendChild(this.logContainer);
            this.showAll = document.getElementById(options.btnShowAll);
            this.showInfo = document.getElementById(options.btnShowInfo);
            this.showWarn = document.getElementById(options.btnShowWarning);
            this.countAll = document.getElementById(options.countAll);
            this.countInfo = document.getElementById(options.countInfo);
            this.countWarn = document.getElementById(options.countWarn);
            this.getBuildLogs(null);
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
        BuildLog.prototype.getBuildLogs = function (event) {
            var _this = this;
            if (this.build) {
                var build = this.build;
                var xmlhttp_1 = new XMLHttpRequest();
                xmlhttp_1.onload = function (evt) {
                    if (xmlhttp_1.status == 200 && _this.container) {
                        _this.updateResult(JSON.parse(xmlhttp_1.response));
                    }
                };
                xmlhttp_1.open("GET", "/porion/api/v1/builds/" + build + "/logs");
                xmlhttp_1.send();
            }
        };
        BuildLog.prototype.updateResult = function (content) {
            var warnCount = 0;
            var infoCount = 0;
            var allCount = 0;
            for (var _i = 0, content_1 = content; _i < content_1.length; _i++) {
                var step = content_1[_i];
                var stepWarn = step.counts.warning + step.counts.error + step.counts.fatal;
                var infoCount = step.counts.info + step.counts.unkown;
                warnCount = warnCount + stepWarn;
                infoCount = infoCount + infoCount + stepWarn;
                allCount = allCount + infoCount + stepWarn + step.counts.debug + step.counts.debug + step.counts.context;
                var stepDiv = document.createElement("div");
                stepDiv.className = 'log-step';
                for (var _a = 0, _b = step.logs; _a < _b.length; _a++) {
                    var log = _b[_a];
                    var div = document.createElement("div");
                    var line = document.createElement("div");
                    var content_2 = document.createElement("div");
                    div.className = 'log-line log-level-' + log.level;
                    line.className = 'log-line-number';
                    line.textContent = log.number.toString();
                    content_2.className = 'log-content';
                    content_2.textContent = log.content;
                    div.appendChild(line);
                    div.appendChild(content_2);
                    stepDiv.appendChild(div);
                }
                this.logContainer.appendChild(stepDiv);
            }
            if (this.countAll) {
                this.countAll.textContent = String(allCount);
            }
            if (this.countInfo) {
                this.countInfo.textContent = String(infoCount);
            }
            if (this.countWarn) {
                this.countWarn.textContent = String(warnCount);
            }
        };
        BuildLog.prototype.setMode = function (event, mode) {
            this.container.classList.remove('build-show-all', 'build-show-info', 'build-show-warning');
            this.container.classList.add(mode);
        };
        return BuildLog;
    }());
    Porion.BuildLog = BuildLog;
    var BuildTests = /** @class */ (function () {
        function BuildTests(options, build) {
            var _this = this;
            this.testContainer = document.createElement('div');
            this.build = "";
            this.build = build;
            this.container = document.getElementById(options.container);
            this.container.appendChild(this.testContainer);
            this.showAll = document.getElementById(options.btnShowAll);
            this.showInfo = document.getElementById(options.btnShowInfo);
            this.showWarn = document.getElementById(options.btnShowWarning);
            this.countAll = document.getElementById(options.countAll);
            this.countInfo = document.getElementById(options.countInfo);
            this.countWarn = document.getElementById(options.countWarn);
            this.getData(null);
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
        BuildTests.prototype.getData = function (event) {
            var _this = this;
            if (this.build) {
                var build = this.build;
                var xmlhttp_2 = new XMLHttpRequest();
                xmlhttp_2.onload = function (evt) {
                    if (xmlhttp_2.status == 200 && _this.container) {
                        _this.updateResult(JSON.parse(xmlhttp_2.response));
                    }
                };
                xmlhttp_2.open("GET", "/porion/api/v1/builds/" + build + "/tests");
                xmlhttp_2.send();
            }
        };
        BuildTests.prototype.updateResult = function (content) {
            var warnCount = 0;
            var infoCount = 0;
            var allCount = 0;
            for (var _i = 0, content_3 = content; _i < content_3.length; _i++) {
                var group = content_3[_i];
                var groupDiv = document.createElement("div");
                groupDiv.className = 'build-xunit-group';
                var groupTestDiv = document.createElement("div");
                groupTestDiv.className = 'build-xunits';
                var groupDuration = 0;
                var groupPass = 0;
                var groupFail = 0;
                var groupTimeout = 0;
                for (var _a = 0, _b = group.tests; _a < _b.length; _a++) {
                    var test = _b[_a];
                    var divTest = document.createElement("div");
                    divTest.className = 'build-xunit';
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
                    div_1.textContent = String(test.duration);
                    div_1.className = 'xunit-duration';
                    divTest.appendChild(div_1);
                    groupTestDiv.appendChild(divTest);
                }
                var divGroup = document.createElement("div");
                divGroup.className = 'build-xunit-group-title';
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
                div.textContent = String(groupDuration);
                divGroup.appendChild(div);
                groupDiv.appendChild(divGroup);
                groupDiv.appendChild(groupTestDiv);
                this.testContainer.appendChild(groupDiv);
            }
        };
        BuildTests.prototype.setMode = function (event, mode) {
            this.container.classList.remove('build-show-all', 'build-show-info', 'build-show-warning');
            this.container.classList.add(mode);
        };
        return BuildTests;
    }());
    Porion.BuildTests = BuildTests;
})(Porion || (Porion = {}));
