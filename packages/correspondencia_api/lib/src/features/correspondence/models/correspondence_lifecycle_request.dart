class CorrespondenceLifecycleRequest {
  const CorrespondenceLifecycleRequest({this.observation});

  final String? observation;

  Map<String, dynamic> toJson() => {
        if (observation != null && observation!.isNotEmpty)
          'observation': observation,
      };
}
