//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./PetAccessControl.sol";

contract EyesLips is PetAccessControl {
    function getEyes(uint256 _id) public view onlyOwner returns (string memory) {
        string[14] memory eyes = [
            '<g id="dead_eyes"><ellipse cx="687.597" cy="282.876" rx="70.84" ry="69.893" style="fill:#fff;stroke:#05000e;stroke-width:23px;"/><ellipse cx="915.153" cy="303.629" rx="53.567" ry="50.632" style="fill:#fff;stroke:#05000e;stroke-width:23px;"/><path d="M660.137,257.969c18.906,18.906 33.99,40.954 49.151,62.853" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M717.479,255.884c-19.56,19.56 -44.869,32.172 -62.927,53.842" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M903.512,282.947c8.981,7.928 18.687,23.222 23.772,33.715" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M943.093,288.523c-9.426,-0 -39.947,21.07 -45.123,28.464" style="fill:none;stroke:#05000e;stroke-width:23px;"/></g>',
            '<g id="normal_eyes"><ellipse cx="673.493" cy="287.437" rx="54.279" ry="69.363" style="fill:#fff;stroke:#05000e;stroke-width:23px;"/><ellipse cx="917.419" cy="310.752" rx="47.61" ry="32.47" style="fill:#fff;stroke:#05000e;stroke-width:23px;"/></g>',
            '<g id="hypno_eyes"><path d="M619.385,305.679c1.543,-27.439 28.936,-52.391 58.388,-46.881c12.171,2.277 21.554,8.514 29.705,17.593c2.038,2.271 5.217,7.787 6.309,10.586c2.561,6.571 3.863,11.602 3.863,18.702c0,26.683 -24.047,48.901 -49.132,48.064c-35.97,-1.2 -50.025,-32.19 -49.133,-48.064Z" style="fill:#fff;stroke:#05000e;stroke-width:23px;"/><path d="M668.518,353.743c-0,0 -22.449,-2.892 -37.137,-19.15c-5.137,-5.687 -9.325,-13.009 -11.27,-22.414c-6.294,-30.437 46.082,-33.687 58.552,-24.681c13.066,9.437 14.672,25.714 -0,34.843c-9.101,5.662 -24.681,-0.726 -27.585,-10.162" style="fill:none;stroke:#000;stroke-width:23px;"/><ellipse cx="902.84" cy="290.032" rx="69.55" ry="65.739" style="fill:#fff;stroke:#05000e;stroke-width:23px;"/><path d="M849.778,250.004c39.728,-26.484 87.287,6.003 88.884,32.923c2.271,38.267 -36.305,44.45 -53.036,37.614c-17.531,-7.163 -24.629,-25.918 -11.391,-41.197c8.21,-9.477 27.524,-6.687 33.82,3.583" style="fill:none;stroke:#000;stroke-width:23px;"/></g>',
            '<g id="toy_eyes"><path d="M695.144,287.856c-23.039,-51.867 -77.978,-31.9 -90.384,23.039c-12.406,54.94 23.039,76.206 35.445,54.94c12.405,-21.267 -22.039,-109.591 -90.739,-90.384c-47.261,13.212 -70.116,80.15 -31.9,113.068c35.799,30.837 20.558,-152.412 -56.003,-52.458" style="fill:none;stroke:#000;stroke-width:23px;"/><path d="M933.045,294.622c35.237,44.489 114.583,0.956 81.791,-44.836c-16.195,-22.616 -38.399,-23.688 -45.114,-0c-6.714,23.687 57.393,71.323 107.496,20.547c50.608,-51.287 -83.764,-89.169 -54.83,-49.506c62.873,86.186 166.864,-154.299 -0,-43.293" style="fill:none;stroke:#000;stroke-width:23px;"/><circle cx="431.79" cy="377.177" r="47.85" style="fill:#fff;stroke:#000;stroke-width:23px;"/><ellipse cx="411.067" cy="399.097" rx="11.146" ry="11.063"/><ellipse cx="1030.17" cy="146.899" rx="28.795" ry="32.878" style="fill:#fff;stroke:#000;stroke-width:23px;"/><ellipse cx="1034.55" cy="135.635" rx="11.542" ry="10.176"/></g>',
            '<g id="sleepless_eyes"><path d="M618.855,265.469c5.861,20.007 10.988,28.678 38.196,30.516c59.82,4.042 71.137,-16.572 75.179,-30.516" style="fill:#fff;stroke:#000;stroke-width:23px;"/><path d="M618.855,265.469l137.677,-0" style="fill:none;stroke:#000;stroke-width:23px;"/><path d="M863.794,263.044c4.622,26.782 8.665,38.389 30.122,40.85c47.175,5.411 56.1,-22.184 59.288,-40.85" style="fill:#fff;stroke:#000;stroke-width:23px;"/><path d="M866.99,321.721c15.147,29.989 62.033,34.598 86.608,-0" style="fill:none;stroke:#000;stroke-width:23px;"/><path d="M618.269,311.912c19.968,48.843 81.775,56.349 114.17,-0" style="fill:none;stroke:#000;stroke-width:23px;"/><ellipse cx="636.427" cy="277.2" rx="9.93" ry="9.856"/><path d="M863.794,263.044l108.575,-0" style="fill:none;stroke:#000;stroke-width:23px;"/><ellipse cx="880.557" cy="278.817" rx="9.93" ry="9.856"/></g>',
            '<g id="confused_eyes"><ellipse cx="663.497" cy="288.846" rx="45.158" ry="28.406" style="fill:#fff;stroke:#05000e;stroke-width:23px;"/><ellipse cx="892.289" cy="297.587" rx="56.305" ry="44.17" style="fill:#fff;stroke:#05000e;stroke-width:23px;"/><path d="M618.339,242.232c17.594,-18.311 32.973,-25.302 59.537,-23.904" style="fill:none;stroke:#000;stroke-width:24px;"/><path d="M868.856,210.499c43.537,4.241 65.966,10.808 93.672,35.089" style="fill:none;stroke:#000;stroke-width:24px;"/></g>',
            '<g id="cyclop_eyes"><ellipse cx="844.699" cy="266.759" rx="75.613" ry="65.981" style="fill:#fff;stroke:#000;stroke-width:24px;"/><path d="M778.378,235.087c49.039,24.659 86.994,21.577 131.834,-1.541" style="stroke:#000;stroke-width:24px;"/><path d="M910.06,233.582l-0.023,-0.034c-21.547,-21.604 -37.874,-33.61 -64.167,-33.056c-32.767,0.69 -45.174,11.071 -67.492,34.595c24.519,12.33 46.268,17.724 67.492,17.146c21.181,-0.577 41.839,-7.102 64.211,-18.619l-0.021,-0.032Z" style="stroke:#000;stroke-width:24px;"/><path d="M945.85,230.554c17.983,30.51 9.768,65.531 -0,85.068" style="stroke:#000;stroke-width:24px;"/><path d="M754.957,225.504c-14.235,20.335 -17.757,45.127 -11.893,68.908" style="stroke:#000;stroke-width:24px;"/></g>',
            '<g id="sleepy_eyes"><path d="M645.349,273.096c15.412,36.988 52.4,57.023 80.141,12.329" style="fill:none;stroke:#000;stroke-width:24px;"/><path d="M893.707,303.197c26.188,45.682 56.74,48.086 69.834,0" style="fill:none;stroke:#000;stroke-width:24px;"/></g>',
            '<g id="drunk_eyes"><ellipse cx="663.899" cy="287.931" rx="38.014" ry="32.393" style="fill:#fff;stroke:#05000e;stroke-width:23px;"/><ellipse cx="907.751" cy="291.631" rx="56.258" ry="49.493" style="fill:#fff;stroke:#05000e;stroke-width:23px;"/><path d="M843.317,313.599c-5.82,-9.693 131.454,-9.693 125.634,-0c-12.32,20.517 -35.846,34.396 -62.817,34.396c-26.972,0 -50.498,-13.879 -62.817,-34.396Z" style="stroke:#05000e;stroke-width:23px;"/><path d="M619.726,305.432c-4.14,-5.957 93.497,-5.957 89.357,0c-8.762,12.609 -25.495,21.139 -44.678,21.139c-19.184,0 -35.917,-8.53 -44.679,-21.139Z" style="stroke:#05000e;stroke-width:23px;"/><ellipse cx="649.256" cy="273.114" rx="11.629" ry="11.316"/><ellipse cx="947.47" cy="290.375" rx="11.235" ry="10.922"/></g>',
            '<g id="nonono_eyes"><path d="M659.357,248.198c18.685,7.49 27.559,11.196 44.333,24.24c16.773,13.045 -33.728,-1.6 -53.423,16.58" style="fill:none;stroke:#000;stroke-width:24px;"/><path d="M952.554,248.134c-31.816,12.12 -44.946,34.34 -51.006,40.905c-6.06,6.565 21.715,-11.615 51.006,7.576" style="fill:none;stroke:#000;stroke-width:24px;"/></g>',
            '<g id="eyes_dots"><ellipse cx="652.952" cy="289.609" rx="16.236" ry="14.193"/><ellipse cx="952.78" cy="289.609" rx="16.236" ry="14.193"/></g>',
            '<g id="demon_eyes"><path d="M626.719,305.2c-0,0 4.429,-39.703 49.281,-50.223c44.851,-10.521 89.148,50.223 89.148,50.223c0,0 -33.776,32.281 -84.165,35.05c-50.388,2.768 -54.264,-35.05 -54.264,-35.05Z" style="fill:#ef851e;stroke:#000;stroke-width:24px;"/><path d="M965.507,313.171c-10.301,-15.049 -14.914,-37.464 -44.503,-30.561c-32.77,7.644 -58.76,33.493 -58.76,33.493c-0,-0 22.263,21.527 55.475,23.373c33.212,1.847 42.55,-16.828 47.788,-26.305Z" style="fill:#ef851e;stroke:#000;stroke-width:24px;"/><path d="M654.744,274.484c-0,-0 -8.251,12.444 -5.408,29.766c2.416,14.712 15.813,29.39 15.813,29.39c-0,0 10.405,-13.1 7.621,-29.39c-3.9,-22.826 -18.026,-29.766 -18.026,-29.766Z" style="fill:#ffe16d;stroke:#000;stroke-width:10.87px;"/><ellipse cx="660.794" cy="304.742" rx="5.998" ry="6.787"/><path d="M920.277,286.296c-0,0 -10.247,11.258 -9.892,26.371c0.302,12.837 11.813,25.218 11.813,25.218c0,-0 12.542,-11.917 12.096,-26.127c-0.625,-19.91 -14.017,-25.462 -14.017,-25.462Z" style="fill:#ffe16d;stroke:#000;stroke-width:10.87px;"/><path d="M923.152,306.615c2.994,0.501 4.978,3.58 4.428,6.872c-0.551,3.293 -3.429,5.559 -6.423,5.059c-2.994,-0.501 -4.978,-3.581 -4.427,-6.873c0.55,-3.292 3.428,-5.559 6.422,-5.058Z"/><path d="M698.503,259.89c-0,0 -15.638,12.161 -18.025,34.721c-2.028,19.162 10.811,42.6 10.811,42.6c-0,-0 18.788,-12.125 20.885,-33.386c2.938,-29.788 -13.671,-43.935 -13.671,-43.935Z" style="fill:#ffe16d;stroke:#000;stroke-width:10.87px;"/><path d="M698.241,291.324c4.477,1.301 7.018,6.123 5.67,10.76c-1.348,4.637 -6.077,7.345 -10.555,6.043c-4.478,-1.301 -7.019,-6.123 -5.671,-10.76c1.348,-4.637 6.078,-7.345 10.556,-6.043Z"/></g>',
            '<g id="strab_eyes"><ellipse cx="692.56" cy="295.383" rx="51.868" ry="47.979" style="fill:#fff;stroke:#05000e;stroke-width:23px;"/><ellipse cx="908.843" cy="309.051" rx="57.199" ry="38.018" style="fill:#fff;stroke:#05000e;stroke-width:23px;"/><ellipse cx="881.53" cy="321.027" rx="17.301" ry="16.711"/><ellipse cx="725.855" cy="308.72" rx="17.755" ry="16.818"/></g>',
            '<g id="enlightened_eyes"><ellipse cx="795.094" cy="251.428" rx="34.143" ry="33.349" style="fill:#fff;stroke:#000;stroke-width:22px;"/><ellipse cx="784.477" cy="256.54" rx="12.275" ry="11.989"/><path d="M621.56,303.004c7.319,29.276 49.769,30.739 64.407,-0" style="fill:none;stroke:#000;stroke-width:22px;"/><path d="M886.506,303.004c13.174,26.348 57.087,46.841 76.117,-0" style="fill:none;stroke:#000;stroke-width:22px;"/><path d="M760.411,213.679c0,-0 3.673,4.987 7.285,10.822" style="fill:none;stroke:#000;stroke-width:16px;"/><path d="M829.092,215.118c-0,-0 -3.674,4.987 -7.285,10.822" style="fill:none;stroke:#000;stroke-width:16px;"/><path d="M798.707,203.271c0,-0 0.415,6.844 0.242,14.37" style="fill:none;stroke:#000;stroke-width:16px;"/><path d="M761.85,290.838c0,-0 3.673,-4.988 7.285,-10.822" style="fill:none;stroke:#000;stroke-width:16px;"/><path d="M830.531,289.399c-0,-0 -3.674,-4.988 -7.285,-10.822" style="fill:none;stroke:#000;stroke-width:16px;"/><path d="M795.829,300.766c0,-0 0.415,-6.844 0.243,-14.37" style="fill:none;stroke:#000;stroke-width:16px;"/></g>'
        ];

        return string(abi.encodePacked('<g id="eyes">',eyes[_id],'</g>'));
    }

    function getEyesType(uint256 _id) public pure returns (string memory) {
        string[14] memory eyesTypes = [
            "Dead",
            "Normal",
            "Hypno",
            "Toy",
            "Sleepless",
            "Confused",
            "Cyclop",
            "Sleepy",
            "Drunk",
            "Nonono",
            "Dots",
            "Demon",
            "Strab",
            "Enlightened"
        ];

        return eyesTypes[_id];
    }

    function getLips(uint256 _id) public view onlyOwner returns (string memory) {
        string[11] memory lips = [
            '<g id="tongue_lips"><path d="M784.351,395.014c-0,17.041 6.095,42.758 21.069,52.574c24.779,16.244 36.619,-22.056 35.225,-40.179" style="fill:#61090f;stroke:#05000e;stroke-width:24px;"/><path d="M713.14,419.878c18.363,-29.036 125.918,-39.199 154.774,1.452" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M713.14,419.878c18.363,-29.036 125.918,-39.199 154.774,1.452" style="fill:none;stroke:#05000e;stroke-width:23px;"/></g>',
            '<g id="cross_lips"><path d="M725.817,390.46c33.259,23.026 76.172,45.308 98.702,56.449" style="fill:none;stroke:#000;stroke-width:24px;"/><path d="M824.519,402.344c-28.967,7.428 -78.317,30.453 -90.119,44.565" style="fill:none;stroke:#000;stroke-width:24px;"/></g>',
            '<g id="derp_lips"><path d="M710.136,399.496c15.554,12.037 18.665,34.107 6.999,47.148" style="fill:none;stroke:#000;stroke-width:24px;"/><path d="M868.01,399.496c-5.444,13.041 -10.11,35.11 3.889,47.148" style="fill:none;stroke:#000;stroke-width:24px;"/><path d="M725.69,423.571l133.693,0" style="fill:none;stroke:#000;stroke-width:24px;"/></g>',
            '<g id="meh_lips"><path d="M806.801,453.051c28.044,-45.469 102.421,-84.443 90.228,-20.569" style="fill:none;stroke:#000;stroke-width:24px;"/></g>',
            '<g id="blee_lips"><path d="M689.531,436.705c-0,-3.766 8.709,-16.027 11.026,-18.278c26.547,-25.792 31.041,26.417 67.95,21.743c24.232,-3.069 31.452,-31.552 51.271,-29.332c24.24,2.714 13.55,38.805 56.808,31.759c17.546,-2.858 21.724,-10.122 25.449,-13.453" style="fill:none;stroke:#000;stroke-width:24px;"/></g>',
            '<g id="normal_lips"><path d="M673.95,429.756c-0,0 39.954,-3.716 68.758,6.505" style="fill:none;stroke:#05000e;stroke-width:23px;"/></g>',
            '<g id="unhappy_lips"><path d="M695.479,433.936c9.591,-21.743 40.475,-48.574 74.841,-42.416c30.075,5.388 48.578,32.209 55.817,56.6" style="fill:none;stroke:#000;stroke-width:24px;"/></g>',
            '<g id="kiss_lips"><path d="M773.942,401.622c-9.773,-11.227 -30.579,-14.721 -33.819,-3.085c-3.322,11.931 21.947,26.289 20.759,26.083c-2.21,-0.384 -26.854,-2.443 -26.183,8.106c1.299,20.435 26.988,24.826 43.952,15.835" style="fill:none;stroke:#000;stroke-width:22px;"/></g>',
            '<g id="hm_lips"><path d="M882.519,420.218c21.977,-18.521 40.09,-15.709 37.809,2.895c-1.909,15.566 -19.423,20.679 -35.335,22.097" style="fill:none;stroke:#000;stroke-width:17.47px;"/><path d="M909.145,407.086c-0,0 -16.287,-14.5 -40.201,-7.284" style="fill:none;stroke:#000;stroke-width:17.47px;"/></g>',
            '<g id="panic_lips"><path d="M657.82,424.71c-5.505,-28.238 12.217,-33.86 38.941,-34.814c26.724,-0.955 44.095,19.852 59.366,17.943c15.271,-1.909 32.26,-18.898 68.528,-17.943c36.269,0.954 41.076,28.978 61.97,17.943c24.861,-13.13 45.157,-11.097 55.8,-0c24.232,25.266 -6.534,47.164 -38.697,41.995c-15.903,-2.556 -29.04,-13.111 -38.593,-14.477c-14.212,-2.032 -36.12,13.555 -51.742,14.477c-34.051,2.01 -58.442,-19.249 -87.075,-14.477c-28.633,4.772 -62.007,22.641 -68.498,-10.647Z" style="fill:#a8121c;stroke:#000;stroke-width:24px;"/></g>',
            '<g id="delirium_lips"><path d="M657.82,424.71c-5.505,-28.238 12.217,-33.86 38.941,-34.814c26.724,-0.955 44.095,19.852 59.366,17.943c15.271,-1.909 32.26,-18.898 68.528,-17.943c36.269,0.954 41.076,28.978 61.97,17.943c24.861,-13.13 45.157,-11.097 55.8,-0c24.232,25.266 -6.534,47.164 -38.697,41.995c-15.903,-2.556 -29.04,-13.111 -38.593,-14.477c-14.212,-2.032 -36.12,13.555 -51.742,14.477c-34.051,2.01 -58.442,-19.249 -87.075,-14.477c-28.633,4.772 -62.007,22.641 -68.498,-10.647Z" style="fill:#a8121c;stroke:#000;stroke-width:24px;"/><path d="M895.471,442.46c-6.826,35.076 -24.576,61.017 4.096,73.305c28.672,12.288 39.595,-20.48 32.768,-47.787c-6.826,-27.306 -30.037,-60.595 -36.864,-25.518Z" style="fill:#2abdf3;stroke:#000;stroke-width:18.2px;"/></g>'
        ];

        return string(abi.encodePacked('<g id="lips">',lips[_id],'</g>'));
    }

    function getLipsType(uint256 _id) public pure returns (string memory) {
        string[11] memory lipsTypes = [
            "Tongue",
            "Cross",
            "Derp",
            "Meh",
            "Blee",
            "Normal",
            "Unhappy",
            "Kiss",
            "Hm",
            "Panic",
            "Delirium"
        ];

        return lipsTypes[_id];
    }
}