import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/presentation/exercise_media.dart';
import '../../training_plan/domain/exercise_catalog.dart';
import '../../training_plan/domain/workout_catalog.dart';
import '../../training_plan/presentation/workout_detail_screen.dart';

enum _DoseFilter { all, reps, duration }

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, required this.placement});

  final CapabilityEstimateRecord placement;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();
  _DoseFilter _doseFilter = _DoseFilter.all;
  bool _withoutEquipment = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      final matchesEquipment =
          !_withoutEquipment || exercise.requiredEquipment.isEmpty;
      return matchesText && matchesDose && matchesEquipment;
    }).toList();
    final workouts = workoutCatalog.where((workout) {
      return query.isEmpty ||
          workout.namePtBr.toLowerCase().contains(query) ||
          workout.objectivePtBr.toLowerCase().contains(query);
    }).toList();

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
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _doseFilter == _DoseFilter.all,
                    onSelected: (_) =>
                        setState(() => _doseFilter = _DoseFilter.all),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Repetições'),
                    selected: _doseFilter == _DoseFilter.reps,
                    onSelected: (_) =>
                        setState(() => _doseFilter = _DoseFilter.reps),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Por tempo'),
                    selected: _doseFilter == _DoseFilter.duration,
                    onSelected: (_) =>
                        setState(() => _doseFilter = _DoseFilter.duration),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Sem equipamento'),
                    selected: _withoutEquipment,
                    onSelected: (value) =>
                        setState(() => _withoutEquipment = value),
                  ),
                ],
              ),
            ),
          ),
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
          _SectionTitle(
            title: query.isEmpty ? 'Catálogo de exercícios' : 'Resultados',
          ),
          if (exercises.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('Nenhum item corresponde aos filtros.'),
                ),
              ),
            )
          else
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
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
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
          '${workout.estimatedMinutes} min · ${workout.level.labelPtBr}\n${workout.objectivePtBr}',
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
