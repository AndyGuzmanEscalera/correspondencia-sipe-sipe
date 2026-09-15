import 'package:correspondencia_sipe_sipe/core/data/local_store.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'public_consult_state.dart';

class PublicConsultCubit extends Cubit<PublicConsultState> {
  PublicConsultCubit({LocalStore? store})
      : _store = store ?? LocalStore.instance,
        super(PublicConsultState(year: DateTime.now().year));

  final LocalStore _store;

  void changeYear(int? year) {
    if (year == null) return;
    emit(state.copyWith(year: year));
  }

  Future<void> consult({
    required String fullName,
    required String documentId,
    required String phone,
    required String uniqueNumberText,
  }) async {
    final uniqueNumber = int.tryParse(uniqueNumberText.trim());
    if (uniqueNumber == null) {
      emit(
        state.copyWith(
          generalStatus: GeneralStatus.error,
          dialogMessage: const DialogMessage(
            message: 'Ingrese un número único de correspondencia válido.',
          ),
        ),
      );
      emit(state.copyWith(generalStatus: GeneralStatus.initial));
      return;
    }

    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(message: 'Consultando trámite...'),
        result: null,
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 500));

    final result = _store.findPublicConsult(
      PublicConsultRequest(
        year: state.year,
        fullName: fullName.trim(),
        documentId: documentId.trim(),
        phone: phone.trim(),
        uniqueNumber: uniqueNumber,
      ),
    );

    if (result == null) {
      emit(
        state.copyWith(
          generalStatus: GeneralStatus.error,
          dialogMessage: const DialogMessage(
            title: 'Trámite no encontrado',
            message:
                'No se encontró una correspondencia con los datos ingresados. Verifique la información e intente nuevamente.',
          ),
        ),
      );
      emit(state.copyWith(generalStatus: GeneralStatus.initial));
      return;
    }

    emit(
      state.copyWith(
        generalStatus: GeneralStatus.success,
        result: result,
        dialogMessage: const DialogMessage(
          title: 'Consulta exitosa',
          message: 'Se encontró el trámite solicitado.',
          showLoading: false,
        ),
      ),
    );
    emit(state.copyWith(generalStatus: GeneralStatus.initial));
  }
}
