angular.module('g2', ['blueimp.fileupload'])

.config(function (fileUploadProvider) {
  angular.extend(fileUploadProvider.defaults, {
    autoUpload: true,
    acceptFileTypes: /(\.|\/)(gif|jpe?g|png)$/i,
    maxFileSize: 10000000,
    disableImageResize: /Android(?!.*Chrome)|Opera/.test(window.navigator.userAgent),
    previewMaxWidth: 250,
    previewMaxHeight: 200,
    //previewThumbnail: false,
  });
})

.controller('FileUploadCtrl', function ($scope, $http) {
  $scope.options = {
  };
});

