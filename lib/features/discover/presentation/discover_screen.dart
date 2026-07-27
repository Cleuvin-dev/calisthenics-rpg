import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/presentation/exercise_media.dart';
import '../../onboarding/domain/training_preferences.dart';
import '../../training_plan/domain/exercise_catalog.dart';
import '../../training_plan/domain/workout_catalog.dart';
import '../../training_plan/presentation/workout_detail_screen.dart';
import '../../workout_session/data/workout_session_providers.dart';
import '../../workout_session/data/workout_session_repository.dart'
    show WorkoutSessionRecordDecoding;

enum _DoseFilter { all, reps, duration }

enum _DurationBucket {
  all(label: 'Todos'),
  under10(label: '< 10 min'),
  from10to20(label: '10–20 min'),
  from20to40(label: '20–40 min'),
  over40(label: '> 40 min');

  const _DurationBucket({required this.label});
  final String label;

  bool matches(int minutes) {
    switch (this) {
      case _DurationBucket.all:
        return true;
      case _DurationBucket.under10:
        return minutes < 10;
      case _DurationBucket.from10to20:
        return minutes >= 10 && minutes < 20;
      case _DurationBucket.from20to40:
        return minutes >= 20 && minutes < 40;
      case _DurationBucket.over40:
        return minutes >= 40;
    }
  }
}

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key, required this.placement});

  final CapabilityEstimateRecord placement;

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();
  _DoseFilter _doseFilter = _DoseFilter.all;
  _DurationBucket _durationBucket = _DurationBucket.all;
  WorkoutLevel? _levelFilter;
  Equipment? _equipmentFilter;
  String? _patternFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesEquipment(Set<Equipment> required, Equipment? filter) {
    if (filter == null) return true;
    if (filter == Equipment.none) return required.isEmpty;
    return required.contains(filter);
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final exercises = exerciseCatalog.where((exercise) {
      final matchesText =
          query.isEmpty ||
          exercise.namePtBr.toLowerCase().contains(query) ||
          exercise.pattern.toLowerCase().contains(query);
      final matchesDose =
          _doseFilter == _DoseFilter.all ||
          (_doseFilter == _DoseFilter.reps &&
              exercise.doseType == DoseType.reps) ||
          (_doseFilter == _DoseFilter.duration &&
              exercise.doseType == DoseType.duration);
      final matchesEquipment = _matchesEquipment(
        exercise.requiredEquipment,
        _equipmentFilter,
      );
      final matchesPattern =
          _patternFilter == null || exercise.pattern == _patternFilter;
      return matchesText && matchesDose && matchesEquipment && matchesPattern;
    }).toList();
    final workouts = workoutCatalog.where((workout) {
      final matchesText =
          query.isEmpty ||
          workout.namePtBr.toLowerCase().contains(query) ||
          workout.objectivePtBr.toLowerCase().contains(query);
      final matchesLevel = _levelFilter == null || workout.level == _levelFilter;
      final matchesDuration = _durationBucket.matches(workout.estimatedMinutes);
      final matchesEquipment = _matchesEquipment(
        workout.equipment,
        _equipmentFilter,
      );
      return matchesText && matchesLevel && matchesDuration && matchesEquipment;
    }).toList();

    final patterns = <String>[];
    for (final exercise in exerciseCatalog) {
      if (!patterns.contains(exercise.pattern)) {
        patterns.add(exercise.pattern);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Descobrir')),
      body: CustomScrollView(
        key: const PageStorageKey('discover-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            sliver: SliverToBoxAdapter(
              child: SearchBar(
                controller: _searchController,
                leading: const Icon(Icons.search),
                hintText: 'Buscar treino, exercício ou habilidade',
                onChanged: (_) => setState(() {}),
                trailing: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      tooltip: 'Limpar busca',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            sliver: SliverToBoxAdapter(
              child: _FilterRow(
                label: 'Nível (treinos)',
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _levelFilter == null,
                    onSelected: (_) => setState(() => _levelFilter = null),
                  ),
                  for (final level in WorkoutLevel.values)
                    ChoiceChip(
                      label: Text(level.labelPtBr),
                      selected: _levelFilter == level,
                      onSelected: (_) => setState(() => _levelFilter = level),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            sliver: SliverToBoxAdapter(
              child: _FilterRow(
                label: 'Duração (treinos)',
                children: [
                  for (final bucket in _DurationBucket.values)
                    ChoiceChip(
                      label: Text(bucket.label),
                      selected: _durationBucket == bucket,
                      onSelected: (_) =>
                          setState(() => _durationBucket = bucket),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            sliver: SliverToBoxAdapter(
              child: _FilterRow(
                label: 'Padrão de movimento (exercícios)',
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _patternFilter == null,
                    onSelected: (_) => setState(() => _patternFilter = null),
                  ),
                  for (final pattern in patterns)
                    ChoiceChip(
                      label: Text(_patternLabel(pattern)),
                      selected: _patternFilter == pattern,
                      onSelected: (_) =>
                          setState(() => _patternFilter = pattern),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            sliver: SliverToBoxAdapter(
              child: _FilterRow(
                label: 'Equipamento',
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _equipmentFilter == null,
                    onSelected: (_) => setState(() => _equipmentFilter = null),
                  ),
                  ChoiceChip(
                    label: const Text('Sem equipamento'),
                    selected: _equipmentFilter == Equipment.none,
                    onSelected: (_) =>
                        setState(() => _equipmentFilter = Equipment.none),
                  ),
                  for (final equipment in Equipment.values.where(
                    (e) => e != Equipment.none,
                  ))
                    ChoiceChip(
                      label: Text(equipment.label),
                      selected: _equipmentFilter == equipment,
                      onSelected: (_) =>
                          setState(() => _equipmentFilter = equipment),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            sliver: SliverToBoxAdapter(
              child: _FilterRow(
                label: 'Tipo de medição',
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _doseFilter == _DoseFilter.all,
                    onSelected: (_) =>
                        setState(() => _doseFilter = _DoseFilter.all),
                  ),
                  ChoiceChip(
                    label: const Text('Repetições'),
                    selected: _doseFilter == _DoseFilter.reps,
                    onSelected: (_) =>
                        setState(() => _doseFilter = _DoseFilter.reps),
                  ),
                  ChoiceChip(
                    label: const Text('Por tempo'),
                    selected: _doseFilter == _DoseFilter.duration,
                    onSelected: (_) =>
                        setState(() => _doseFilter = _DoseFilter.duration),
                  ),
                  Tooltip(
                    message: 'Favoritos ainda não estão disponíveis nesta versão',
                    child: ChoiceChip(
                      label: const Text('Favoritos'),
                      selected: false,
                      onSelected: null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (query.isEmpty) const _RecentExercisesSliver(),
          if (workouts.isNotEmpty) ...[
            const _SectionTitle(title: 'Treinos disponíveis'),
            SliverList.builder(
              itemCount: workouts.length,
              itemBuilder: (context, index) {
                final workout = workouts[index];
                return _WorkoutCard(
                  workout: workout,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WorkoutDetailScreen(
                        workout: workout,
                        placement: widget.placement,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          if (exercises.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    workouts.isEmpty
                        ? 'Nenhum item corresponde aos filtros.'
                        : 'Nenhum exercício corresponde aos filtros.',
                  ),
                ),
              ),
            )
          else if (_patternFilter != null || query.isNotEmpty)
            ...[
              _SectionTitle(
                title: query.isEmpty ? 'Catálogo de exercícios' : 'Resultados',
              ),
              SliverList.builder(
                itemCount: exercises.length,
                itemBuilder: (context, index) => _ExerciseCard(
                  exercise: exercises[index],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ExerciseDetailScreen(exercise: exercises[index]),
                    ),
                  ),
                ),
              ),
            ]
          else
            for (final pattern in patterns)
              if (exercises.any((e) => e.pattern == pattern)) ...[
                _SectionTitle(title: _patternLabel(pattern)),
                SliverList.builder(
                  itemCount: exercises
                      .where((e) => e.pattern == pattern)
                      .length,
                  itemBuilder: (context, index) {
                    final item = exercises
                        .where((e) => e.pattern == pattern)
                        .toList()[index];
                    return _ExerciseCard(
                      exercise: item,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ExerciseDetailScreen(exercise: item),
                        ),
                      ),
                    );
                  },
                ),
              ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _RecentExercisesSliver extends ConsumerWidget {
  const _RecentExercisesSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentSessionsAsync = ref.watch(recentCompletedSessionsProvider);
    return recentSessionsAsync.when(
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (sessions) {
        final seenSlugs = <String>{};
        final recent = <CatalogExercise>[];
        for (final session in sessions) {
          for (final item in session.items) {
            if (seenSlugs.add(item.exerciseSlug)) {
              final exercise = catalogExerciseForSlug(item.exerciseSlug);
              if (exercise != null) recent.add(exercise);
            }
          }
          if (recent.length >= 8) break;
        }
        if (recent.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
        return SliverMainAxisGroup(
          slivers: [
            const _SectionTitle(title: 'Recentes'),
            SliverList.builder(
              itemCount: recent.length,
              itemBuilder: (context, index) => _ExerciseCard(
                exercise: recent[index],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExerciseDetailScreen(exercise: recent[index]),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 4),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final child in children) ...[
              child,
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    sliver: SliverToBoxAdapter(
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.workout, required this.onTap});
  final Workout workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Card(
      child: ListTile(
        minVerticalPadding: 16,
        leading: const Icon(Icons.fitness_center, size: 32),
        title: Text(workout.namePtBr),
        subtitle: Text(
          '${workout.estimatedMinutes} min · ${workout.level.labelPtBr}\n'
          '${workout.objectivePtBr}\n'
          '${workout.equipment.isEmpty ? 'Sem equipamento' : workout.equipment.map((e) => e.label).join(', ')}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    ),
  );
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.onTap});
  final CatalogExercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ExerciseMedia(
                exerciseSlug: exercise.slug,
                pattern: exercise.pattern,
                namePtBr: exercise.namePtBr,
                mediaSlug: exercise.mediaSlug,
                size: 88,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.namePtBr,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(exercise.setsRepsGuidance),
                    const SizedBox(height: 4),
                    Text(
                      '${_patternLabel(exercise.pattern)} · descanso ${exercise.restSeconds}s',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      exercise.requiredEquipment.isEmpty
                          ? 'Sem equipamento'
                          : exercise.requiredEquipment
                                .map((e) => e.label)
                                .join(', '),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    ),
  );
}

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});
  final CatalogExercise exercise;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Como executar')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ExerciseMedia(
            exerciseSlug: exercise.slug,
            pattern: exercise.pattern,
            namePtBr: exercise.namePtBr,
            mediaSlug: exercise.mediaSlug,
            size: 240,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          exercise.namePtBr,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(exercise.setsRepsGuidance),
        const SizedBox(height: 16),
        _DetailRow(label: 'Padrão', value: _patternLabel(exercise.pattern)),
        _DetailRow(
          label: 'Descanso',
          value: '${exercise.restSeconds} segundos',
        ),
        _DetailRow(
          label: 'Medição',
          value: exercise.doseType == DoseType.duration
              ? 'Tempo'
              : 'Repetições',
        ),
        _DetailRow(
          label: 'Equipamento',
          value: exercise.requiredEquipment.isEmpty
              ? 'Sem equipamento obrigatório'
              : exercise.requiredEquipment.map((e) => e.label).join(', '),
        ),
        const SizedBox(height: 16),
        const Text(
          'As instruções editoriais detalhadas, erros comuns e contraindicações ainda não existem para este item do catálogo. Use a demonstração visual e interrompa se sentir dor.',
        ),
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Flexible(child: Text(value, textAlign: TextAlign.end)),
  );
}

String _patternLabel(String pattern) => pattern
    .split('_')
    .map(
      (part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');
