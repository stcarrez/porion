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
namespace Porion {
    export class BarGraph {

        constructor(container: string, legend: string, series: jquery.flot.dataSeries[], ticks: any) {
            var div : HTMLElement = document.getElementById(container);
            $.plot($(div), series, {
                series: {
                    bars: {
                        show: true,
                        horizontal: true,
                        align: "center"
                    }
                },
                legend: {
                    show: false,
                    backgroundOpacity: 0.5
                },
                xaxis: {
                    ticks: [],
                    color: "#993D00"
                },
                yaxis: {
                    ticks: ticks,
                    tickSize: [ 10, "px" ],
                    font: { size: 18, style: "normal" },
                    show: true,
                    color: "#993D00",
                    tickColor: "#00ff00"
                }
            });
        }
    }

    export interface BuildTestInfo {
       build_id: number,
       build_number: number,
       build_date: string,
       build_status: string,
       pass_count: number,
       fail_count: number,
       timeout_count : number,
       test_duration: number
    }
    export interface BuildTests {
       project_id: string,
       tests: BuildTestInfo[]
    }

    export interface BuildCoverageInfo {
       build_id: number,
       build_number: number,
       build_date: string,
       build_status: string,
       lines: number,
       functions: number
    }
    export interface BuildCoverage {
       project_id: string,
       metrics: BuildCoverageInfo[]
    }

    export interface Options {
        container: string,
        btnShowAll: string,
        btnShowInfo: string,
        btnShowWarning: string,
	countAll: string,
	countInfo: string,
	countWarn: string
    }
    export class TestChart {
        readonly graphContainer : HTMLDivElement = <HTMLDivElement>document.createElement('div');
        container  : HTMLElement | null;
        project    : string = "";

        constructor(options : Options, project: string) {
            this.container = document.getElementById(options.container);
            this.container.appendChild(this.graphContainer);
	    this.project = project;
            this.getData(null)
	}
        getData(event : Event) {
            if (this.project) {
                const project : string = this.project;
                const xmlhttp : XMLHttpRequest = new XMLHttpRequest();
                
                xmlhttp.onload = evt => {
                    if (xmlhttp.status == 200 && this.container) {
                        this.updateData(JSON.parse(xmlhttp.response));
                    }
                };
                xmlhttp.open("GET", "/porion/api/v1/projects/" + project + "/tests/builds");
                xmlhttp.send();
            }
        }
	updateData(content : BuildTests) {
	   var pass : number[][] = new Array();
	   var fail : number[][] = new Array();
	   var timeout : number[][] = new Array();
	   var duration : number[][] = new Array();
	   var first_build : number = 10000;
	   var last_build : number = 0;
           for (var test of content.tests) {
	      if (test.build_status == "BUILD_PASS") {
	      	 if (test.build_number < first_build) {
	            first_build = test.build_number;
	      	 }
	      	 if (test.build_number > last_build) {
                    last_build = test.build_number;
	      	 }
	      	 timeout.push([test.build_number, test.timeout_count]);
	      	 fail.push([test.build_number, test.fail_count + test.timeout_count]);
	      	 pass.push([test.build_number, test.pass_count + test.fail_count + test.timeout_count]);
	      	 duration.push([test.build_number, test.test_duration]);
	      }
	   }
           $.plot($(this.container), [ timeout, fail, pass ], {
                colors: [ "red", "green", "blue"],
                series: {
                    lines: {
                        show: true,
			fill: true
                    },
		    points: {
		        show: true
		    },
		    clickable: true,
		    hoverable: true
                },
		grid: {
		   hoverable: true,
		   clickable: true
		},
                xaxis: {
                    color: "#993D00",
		    show: true
                },
		yaxis: {
		    show: true
		},
                legend: {
                    show: false
                }
            });
	}
    }

    export class CoverageChart {
        readonly graphContainer : HTMLDivElement = <HTMLDivElement>document.createElement('div');
        readonly legendContainer : HTMLDivElement = <HTMLDivElement>document.createElement('div');
        readonly tooltipContainer : HTMLDivElement = <HTMLDivElement>document.createElement('div');
        container  : HTMLElement | null;
        project    : string = "";

        constructor(options : Options, project: string) {
            this.container = document.getElementById(options.container);
	    
            this.container.appendChild(this.graphContainer);
	    this.container.appendChild(this.legendContainer);
	    this.project = project;
	    this.legendContainer.className = 'graph-legend';
	    this.graphContainer.className = 'graph-view';
	    this.tooltipContainer.className = 'graph-tooltip';
	    document.body.appendChild(this.tooltipContainer);
            this.getData(null)
	}
        getData(event : Event) {
            if (this.project) {
                const project : string = this.project;
                const xmlhttp : XMLHttpRequest = new XMLHttpRequest();
                
                xmlhttp.onload = evt => {
                    if (xmlhttp.status == 200 && this.container) {
                        this.updateData(JSON.parse(xmlhttp.response));
                    }
                };
                xmlhttp.open("GET", "/porion/api/v1/projects/" + project + "/coverage");
                xmlhttp.send();
            }
        }
	updateData(content : BuildCoverage) {
	   var lines : number[][] = new Array();
	   var functions : number[][] = new Array();
	   var first_build : number = 10000;
	   var last_build : number = 0;
           for (var build of content.metrics) {
	      if (build.build_status == "BUILD_PASS") {
	      	 if (build.build_number < first_build) {
	            first_build = build.build_number;
	      	 }
	      	 if (build.build_number > last_build) {
                    last_build = build.build_number;
	      	 }
	      	 lines.push([build.build_number, build.lines / 10.0]);
	      	 functions.push([build.build_number, build.functions / 10.0]);
	      }
	   }
           $.plot($(this.graphContainer), [ { data: lines, label: "Lines" }, { data: functions, label: "Functions" }], {
                colors: [ "green", "blue"],
                series: {
                    lines: {
                        show: true,
			fill: false
                    },
		    points: {
		        show: true
		    },
		    clickable: true,
		    hoverable: true
                },
		grid: {
		   hoverable: true,
		   clickable: true
		},
                xaxis: {
                    color: "#993D00",
		    show: true
                },
		yaxis: {
		    show: true
		},
                legend: {
                    show: true,
		    margin: [-100, -50],
		    backgroundOpacity: 0.5,
		    container: this.legendContainer
                }
            });
	    var t = this;
	    $(this.graphContainer).bind("plothover", function (event, pos, item) {
	       if (!pos.x || !pos.y) {
	          return;
	       }
	       if (item) {
	          var build_number : number = item.datapoint[0];
		  var cover : number = item.datapoint[1];
	          $(t.tooltipContainer).html("Build " + build_number + " Coverage: " + cover).css({top: item.pageY+5, left: item.pageX+5}).fadeIn(200);
	       } else {
	          $(t.tooltipContainer).stop().hide();
	       }
	    });
	}
    }
/*    export class PieChart {

        constructor(container: string, legend: string, series: jquery.flot.dataSeries[], ticks: any) {
            var div : HTMLElement = document.getElementById(container);
            $.plot($(div), series, {
                series: {
                    pie: {
                        show: true,
                        startAngle: 1.0, radius: 1.0, innerRadius: 0.5, tilt: 1.0, offset: { top: 0, left: 0 },
                        label: { show: true }
                    }
                },
                legend: {
                    show: false
                }
            });
        }
    }*/
}
