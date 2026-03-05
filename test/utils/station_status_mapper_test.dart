import 'package:flutter_test/flutter_test.dart';
import 'package:metropty/models/station_model.dart';
import 'package:metropty/utils/station_status_mapper.dart';

void main() {
  group('StationStatusMapper', () {
    group('mapToEstadoActual', () {
      test('mapea yes + crowd 1-2 a normal', () {
        expect(
          StationStatusMapper.mapToEstadoActual(
            stationOperational: 'yes',
            stationCrowd: 1,
          ),
          equals(EstadoEstacion.normal),
        );
        expect(
          StationStatusMapper.mapToEstadoActual(
            stationOperational: 'yes',
            stationCrowd: 2,
          ),
          equals(EstadoEstacion.normal),
        );
      });

      test('mapea yes + crowd 3 a moderado', () {
        expect(
          StationStatusMapper.mapToEstadoActual(
            stationOperational: 'yes',
            stationCrowd: 3,
          ),
          equals(EstadoEstacion.moderado),
        );
      });

      test('mapea yes + crowd 4-5 a lleno', () {
        expect(
          StationStatusMapper.mapToEstadoActual(
            stationOperational: 'yes',
            stationCrowd: 4,
          ),
          equals(EstadoEstacion.lleno),
        );
        expect(
          StationStatusMapper.mapToEstadoActual(
            stationOperational: 'yes',
            stationCrowd: 5,
          ),
          equals(EstadoEstacion.lleno),
        );
      });

      test('mapea partial a moderado', () {
        expect(
          StationStatusMapper.mapToEstadoActual(
            stationOperational: 'partial',
            stationCrowd: null,
          ),
          equals(EstadoEstacion.moderado),
        );
      });

      test('mapea no a cerrado', () {
        expect(
          StationStatusMapper.mapToEstadoActual(
            stationOperational: 'no',
            stationCrowd: null,
          ),
          equals(EstadoEstacion.cerrado),
        );
      });

      test('retorna null para valores null', () {
        expect(
          StationStatusMapper.mapToEstadoActual(
            stationOperational: null,
            stationCrowd: null,
          ),
          isNull,
        );
      });

      test('mapea yes sin crowd a normal por defecto', () {
        expect(
          StationStatusMapper.mapToEstadoActual(
            stationOperational: 'yes',
            stationCrowd: null,
          ),
          equals(EstadoEstacion.normal),
        );
      });
    });

    group('mapToAglomeracion', () {
      test('mapea crowd correctamente', () {
        expect(StationStatusMapper.mapToAglomeracion(1), equals(1));
        expect(StationStatusMapper.mapToAglomeracion(3), equals(3));
        expect(StationStatusMapper.mapToAglomeracion(5), equals(5));
      });

      test('clamp valores fuera de rango', () {
        expect(StationStatusMapper.mapToAglomeracion(0), equals(1));
        expect(StationStatusMapper.mapToAglomeracion(10), equals(5));
      });

      test('retorna null para null', () {
        expect(StationStatusMapper.mapToAglomeracion(null), isNull);
      });
    });

    group('mapToConfidenceString', () {
      test('mapea confidence >= 0.7 a high', () {
        expect(
          StationStatusMapper.mapToConfidenceString(0.7),
          equals('high'),
        );
        expect(
          StationStatusMapper.mapToConfidenceString(0.9),
          equals('high'),
        );
        expect(
          StationStatusMapper.mapToConfidenceString(1.0),
          equals('high'),
        );
      });

      test('mapea confidence >= 0.4 a medium', () {
        expect(
          StationStatusMapper.mapToConfidenceString(0.4),
          equals('medium'),
        );
        expect(
          StationStatusMapper.mapToConfidenceString(0.6),
          equals('medium'),
        );
      });

      test('mapea confidence < 0.4 a low', () {
        expect(
          StationStatusMapper.mapToConfidenceString(0.3),
          equals('low'),
        );
        expect(
          StationStatusMapper.mapToConfidenceString(0.0),
          equals('low'),
        );
      });

      test('retorna null para null', () {
        expect(StationStatusMapper.mapToConfidenceString(null), isNull);
      });
    });

    group('parseEstadoEstacion y estadoEstacionToString', () {
      test('parse y toString son inversos', () {
        final estados = [
          EstadoEstacion.normal,
          EstadoEstacion.moderado,
          EstadoEstacion.lleno,
          EstadoEstacion.cerrado,
        ];

        for (final estado in estados) {
          final string = StationStatusMapper.estadoEstacionToString(estado);
          final parsed = StationStatusMapper.parseEstadoEstacion(string);
          expect(parsed, equals(estado));
        }
      });
    });
  });
}
