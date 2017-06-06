var argscheck = require('cordova/argscheck'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec');


var AwsUserPoolPlugin = function(config, successCallback, errorCallback) {
	cordova.exec(function(params) {
		successCallback();
	},
	function(error) {
		errorCallback(error);
	}, "AwsUserPoolPlugin", "init", [config]);
};


AwsUserPoolPlugin.prototype.login = function(config, successCallback, errorCallback) {
	cordova.exec(function(params) {
		successCallback(params);
	},
	function(error) {
		errorCallback(error);
	}, "AwsUserPoolPlugin", "loginUser", [config]);
};

AwsUserPoolPlugin.prototype.logout = function(config, successCallback, errorCallback) {
	cordova.exec(function(params) {
		successCallback(params);
	},
	function(error) {
		errorCallback(error);
	}, "AwsUserPoolPlugin", "loginUser", [config]);
};

AwsUserPoolPlugin.prototype.signIn = function(config, successCallback, errorCallback) {
	cordova.exec(function(params) {
		successCallback(params);
	},
	function(error) {
		errorCallback(error);
	}, "AwsUserPoolPlugin", "logout", [config]);
};
  
//added to allow getting a fresh token each time it is needed...DONT KNOW IF THIS IS BEST PRACTICE???
AwsUserPoolPlugin.prototype.getToken = function(config, successCallback, errorCallback) {
	cordova.exec(function(params) {
		successCallback(params);
	},
	function(error) {
		errorCallback(error);
	}, "AwsUserPoolPlugin", "refreshSession", [config]);
};

AwsUserPoolPlugin.prototype.signIn = function(config, successCallback, errorCallback) {
	cordova.exec(function(params) {
		successCallback(params);
	},
	function(error) {
		errorCallback(error);
	}, "AwsUserPoolPlugin", "signIn", [config]);
};

AwsUserPoolPlugin.prototype.offlineSignIn = function(config, successCallback, errorCallback) {
	cordova.exec(function(params) {
		successCallback(params);
	},
	function(error) {
		errorCallback(error);
	}, "AwsUserPoolPlugin", "offlineSignIn", [config]);
};

AwsUserPoolPlugin.prototype.signOut = function(config, successCallback, errorCallback) {
	cordova.exec(function(params) {
		successCallback(params);
	},
	function(error) {
		errorCallback(error);
	}, "AwsUserPoolPlugin", "signOut", [config]);
};

AwsUserPoolPlugin.prototype.signUp = function(config, successCallback, errorCallback) {
	cordova.exec(function(params) {
		successCallback(params);
	},
	function(error) {
		errorCallback(error);
	}, "AwsUserPoolPlugin", "signUp", [config]);
};

AwsUserPoolPlugin.prototype.confirmSignUp = function(config, successCallback, errorCallback) {
	cordova.exec(function(params) {
		successCallback(params);
	},
	function(error) {
		errorCallback(error);
	}, "AwsUserPoolPlugin", "confirmSignUp", [config]);
};

AwsUserPoolPlugin.prototype.forgotPassword = function(config, successCallback, errorCallback) {
	cordova.exec(function(params) {
		successCallback(params);
	},
	function(error) {
		errorCallback(error);
	}, "AwsUserPoolPlugin", "forgotPassword", [config]);
};

AwsUserPoolPlugin.prototype.updatePassword = function(config, successCallback, errorCallback) {
	cordova.exec(function(params) {
		successCallback(params);
	},
	function(error) {
		errorCallback(error);
	}, "AwsUserPoolPlugin", "updatePassword", [config]);
};

AwsUserPoolPlugin.prototype.getDetails = function(config, successCallback, errorCallback) {
	cordova.exec(function(userDetails) {
		successCallback(userDetails);
	},
	function(error) {
		errorCallback(error);
	}, "AwsUserPoolPlugin", "getDetails", [config]);
};

AwsUserPoolPlugin.prototype.resendConfirmationCode = function(config, successCallback, errorCallback) {
	cordova.exec(function(params) {
		successCallback(params);
	},
	function(error) {
		errorCallback(error);
	}, "AwsUserPoolPlugin", "resendConfirmationCode", [config]);
};

AwsUserPoolPlugin.prototype.createAWSCognitoDataset = function(config, successCallback, errorCallback) {
	cordova.exec(function(params) {
		successCallback(params);
	},
	function(error) {
		errorCallback(error);
	}, "AwsUserPoolPlugin", "createAWSCognitoDataset", [config]);
};

AwsUserPoolPlugin.prototype.getUserDataCognitoSync = function(config, successCallback, errorCallback) {
	cordova.exec(function(params) {
		successCallback(params);
	},
	function(error) {
		errorCallback(error);
	}, "AwsUserPoolPlugin", "getUserDataCognitoSync", [config]);
};

AwsUserPoolPlugin.prototype.setUserDataCognitoSync = function(config, successCallback, errorCallback) {
	cordova.exec(function(params) {
		successCallback(params);
	},
	function(error) {
		errorCallback(error);
	}, "AwsUserPoolPlugin", "setUserDataCognitoSync", [config]);
};

AwsUserPoolPlugin.prototype.callAWSLambdaFunction = function(config, successCallback, errorCallback) {
	cordova.exec(function(params) {
		successCallback(params);
	},
	function(error) {
		errorCallback(error);
	}, "AwsUserPoolPlugin", "callAWSLambdaFunction", [config]);
};

module.exports = AwsUserPoolPlugin;