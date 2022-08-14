/*
 *  nodes -- Display graphs for build node usages
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
    function durationFormatter(v, axis) {
        var secs = v / 1000;
        var min = Math.floor(secs / 60);
        var hour = Math.floor(min / 60);
        if (hour > 0) {
            min = min % 60;
            secs = secs % 60;
            return hour.toFixed(0) + ":" + min.toFixed(0) + ":" + secs.toFixed(0);
        }
        if (min > 0) {
            secs = secs % 60;
            return min.toFixed(0) + ":" + secs.toFixed(0);
        }
        return secs.toFixed(axis.tickDecimals) + " s";
    }
    var NodeUsageChart = /** @class */ (function () {
        function NodeUsageChart(options, node) {
            this.durationGraphContainer = document.createElement('div');
            this.systemGraphContainer = document.createElement('div');
            this.durationLegendContainer = document.createElement('div');
            this.systemLegendContainer = document.createElement('div');
            this.tooltipContainer = document.createElement('div');
            this.node = "";
            this.durationContainer = document.getElementById(options.durationContainer);
            if (this.durationContainer) {
                this.durationContainer.appendChild(this.durationGraphContainer);
                this.durationContainer.appendChild(this.durationLegendContainer);
                this.durationLegendContainer.className = 'graph-legend';
                this.durationGraphContainer.className = 'graph-view';
            }
            this.systemContainer = document.getElementById(options.systemContainer);
            if (this.systemContainer) {
                this.systemContainer.appendChild(this.systemGraphContainer);
                this.systemContainer.appendChild(this.systemLegendContainer);
                this.systemLegendContainer.className = 'graph-legend';
                this.systemGraphContainer.className = 'graph-view';
            }
            this.node = node;
            this.tooltipContainer.className = 'graph-tooltip';
            document.body.appendChild(this.tooltipContainer);
            this.getData(null);
        }
        NodeUsageChart.prototype.getData = function (event) {
            var _this = this;
            if (this.node) {
                var node = this.node;
                var xmlhttp_1 = new XMLHttpRequest();
                xmlhttp_1.onload = function (evt) {
                    if (xmlhttp_1.status == 200 && (_this.durationContainer || _this.systemContainer)) {
                        _this.updateData(JSON.parse(xmlhttp_1.response));
                    }
                };
                xmlhttp_1.open("GET", "/porion/api/v1/nodes/" + node + "/usage");
                xmlhttp_1.send();
            }
        };
        NodeUsageChart.prototype.updateData = function (content) {
            var build_duration_pass = new Array();
            var build_duration_fail = new Array();
            var user_time = new Array();
            var sys_time = new Array();
            var prevDate;
            var build_pass;
            var build_fail;
            for (var _i = 0, content_1 = content; _i < content_1.length; _i++) {
                var usage = content_1[_i];
                if (usage.date != prevDate) {
                    if (prevDate) {
                        var offset = 0;
                        var day_user_time = 0;
                        var day_sys_time = 0;
                        var day = Math.floor(new Date(prevDate).getTime() / 1000);
                        if (build_fail) {
                            build_duration_fail.push([day, build_fail.build_duration]);
                            offset = build_fail.build_duration;
                            day_user_time = build_fail.user_time;
                            day_sys_time = build_fail.sys_time;
                        }
                        if (build_pass) {
                            build_duration_pass.push([day, build_pass.build_duration + offset]);
                            day_user_time += build_pass.user_time;
                            day_sys_time += build_pass.sys_time;
                        }
                        sys_time.push([day, day_sys_time]);
                        user_time.push([day, day_sys_time + day_user_time]);
                    }
                    prevDate = usage.date;
                    build_pass = null;
                    build_fail = null;
                }
                if (usage.build_status == "BUILD_PASS") {
                    build_pass = usage;
                }
                else {
                    build_fail = usage;
                }
            }
            if (prevDate) {
                var offset = 0;
                var day_user_time = 0;
                var day_sys_time = 0;
                var day = Math.floor(new Date(prevDate).getTime() / 1000);
                if (build_fail) {
                    build_duration_fail.push([day, build_fail.build_duration]);
                    offset = build_fail.build_duration;
                    day_user_time = build_fail.user_time;
                    day_sys_time = build_fail.sys_time;
                }
                if (build_pass) {
                    build_duration_pass.push([day, build_pass.build_duration + offset]);
                    day_user_time += build_pass.user_time;
                    day_sys_time += build_pass.sys_time;
                }
                sys_time.push([day, day_sys_time]);
                user_time.push([day, day_sys_time + day_user_time]);
            }
            if (this.durationContainer) {
                $.plot($(this.durationContainer), [build_duration_fail, build_duration_pass], {
                    colors: ["red", "green", "blue"],
                    series: {
                        lines: {
                            show: true,
                            fill: true
                        },
                        points: {
                            show: false
                        },
                        clickable: true,
                        hoverable: true
                    },
                    grid: {
                        hoverable: true,
                        clickable: true
                    },
                    xaxis: {
                        mode: "time",
                        color: "#993D00",
                        show: true
                    },
                    yaxis: {
                        show: true,
                        tickFormatter: durationFormatter
                    },
                    legend: {
                        show: true,
                        margin: [-100, -50],
                        backgroundOpacity: 0.5,
                        container: this.durationLegendContainer
                    }
                });
                var t = this;
                $(this.durationGraphContainer).bind("plothover", function (event, pos, item) {
                    if (!pos.x || !pos.y) {
                        return;
                    }
                    if (item) {
                        var build_number = item.datapoint[0];
                        var cover = item.datapoint[1];
                        $(t.tooltipContainer).html("Build " + build_number + " Coverage: " + cover).css({ top: item.pageY + 5, left: item.pageX + 5 }).fadeIn(200);
                    }
                    else {
                        $(t.tooltipContainer).stop().hide();
                    }
                });
            }
            if (this.systemContainer) {
                $.plot($(this.systemContainer), [sys_time, user_time], {
                    colors: ["red", "green", "blue"],
                    series: {
                        lines: {
                            show: true,
                            fill: true
                        },
                        points: {
                            show: false
                        },
                        clickable: true,
                        hoverable: true
                    },
                    grid: {
                        hoverable: true,
                        clickable: true
                    },
                    xaxis: {
                        mode: "time",
                        color: "#993D00",
                        show: true
                    },
                    yaxis: {
                        show: true,
                        tickFormatter: durationFormatter
                    },
                    legend: {
                        show: true,
                        margin: [-100, -50],
                        backgroundOpacity: 0.5,
                        container: this.systemLegendContainer
                    }
                });
                var t = this;
                $(this.systemGraphContainer).bind("plothover", function (event, pos, item) {
                    if (!pos.x || !pos.y) {
                        return;
                    }
                    if (item) {
                        var build_number = item.datapoint[0];
                        var cover = item.datapoint[1];
                        $(t.tooltipContainer).html("Build " + build_number + " Coverage: " + cover).css({ top: item.pageY + 5, left: item.pageX + 5 }).fadeIn(200);
                    }
                    else {
                        $(t.tooltipContainer).stop().hide();
                    }
                });
            }
        };
        return NodeUsageChart;
    }());
    Porion.NodeUsageChart = NodeUsageChart;
})(Porion || (Porion = {}));
