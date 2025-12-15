import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

/// Servicio para gestión de laboratorios
class LaboratoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Generar código de invitación aleatorio
  String _generateInvitationCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Crear nuevo laboratorio y registrar al usuario como admin
  Future<Map<String, dynamic>> createLaboratory({
    required String laboratoryName,
    required String adminEmail,
    required String adminPassword,
    required String adminName,
  }) async {
    try {
      // 1. Registrar usuario en Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: adminEmail,
        password: adminPassword,
      );

      if (authResponse.user == null) {
        throw Exception('Error al crear usuario');
      }

      final userId = authResponse.user!.id;

      // 2. Generar código de invitación
      final invitationCode = _generateInvitationCode();

      // 3. Crear laboratorio
      final labResponse = await _supabase
          .from('laboratories')
          .insert({'name': laboratoryName, 'invitation_code': invitationCode})
          .select()
          .single();

      final laboratoryId = labResponse['id'];

      // 4. Crear perfil del usuario admin
      await _supabase.from('user_profiles').insert({
        'id': userId,
        'laboratory_id': laboratoryId,
        'full_name': adminName,
        'role': 'admin',
      });

      return {
        'success': true,
        'laboratory_id': laboratoryId,
        'invitation_code': invitationCode,
      };
    } catch (e) {
      throw Exception('Error al crear laboratorio: $e');
    }
  }

  /// Unir usuario a laboratorio existente usando código de invitación
  Future<Map<String, dynamic>> joinLaboratory({
    required String invitationCode,
    required String userEmail,
    required String userPassword,
    required String userName,
  }) async {
    try {
      // 1. Buscar laboratorio por código de invitación
      final labResponse = await _supabase
          .from('laboratories')
          .select()
          .eq('invitation_code', invitationCode.toUpperCase())
          .maybeSingle();

      if (labResponse == null) {
        throw Exception('Código de invitación inválido');
      }

      final laboratoryId = labResponse['id'];

      // 2. Registrar usuario en Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: userEmail,
        password: userPassword,
      );

      if (authResponse.user == null) {
        throw Exception('Error al crear usuario');
      }

      final userId = authResponse.user!.id;

      // 3. Crear perfil del usuario vinculado al laboratorio
      await _supabase.from('user_profiles').insert({
        'id': userId,
        'laboratory_id': laboratoryId,
        'full_name': userName,
        'role': 'user',
      });

      return {
        'success': true,
        'laboratory_id': laboratoryId,
        'laboratory_name': labResponse['name'],
      };
    } catch (e) {
      throw Exception('Error al unirse al laboratorio: $e');
    }
  }

  /// Obtener información del laboratorio del usuario actual
  Future<Map<String, dynamic>?> getCurrentUserLaboratory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('user_profiles')
          .select('laboratory_id, laboratories(id, name, invitation_code)')
          .eq('id', userId)
          .single();

      return response['laboratories'];
    } catch (e) {
      return null;
    }
  }

  /// Obtener perfil del usuario actual
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      return await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();
    } catch (e) {
      return null;
    }
  }
}
