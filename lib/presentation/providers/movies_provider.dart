import 'package:flutter/material.dart';
import '../../data/models/movies_model.dart';

class MovieProvider extends ChangeNotifier {
  final List<Movie> _nowPlaying = [
    Movie(
      id: '1',
      title: 'The Conjuring',
      thumbnail:
          'https://image.tmdb.org/t/p/w500/wVYREutTvI2tmxr6ujrHT704wGF.jpg',
      rating: 7.5,
      year: '2013',
    ),
    Movie(
      id: '2',
      title: 'Toxic Avenger',
      thumbnail:
          'https://picsum.photos/seed/action1/300/450',
      rating: 6.2,
      year: '2023',
    ),
    Movie(
      id: '3',
      title: 'Demon Slayer: Kimetsu no Yaiba',
      thumbnail:
          'https://image.tmdb.org/t/p/w500/xUfRZu2mi8jH6SzQEJGP6tjBuYj.jpg',
      rating: 8.7,
      year: '2021',
    ),
    Movie(
      id: '4',
      title: 'Playing with Fire',
      thumbnail:
           'https://image.tmdb.org/t/p/w500/2cxhvwyEwRlysAmRH4iodkvo0z5.jpg',
      rating: 6.1,
      year: '2019',
    ),
    Movie(
      id: '5',
      title: 'The Nun II',
      thumbnail:
          'https://image.tmdb.org/t/p/w500/5gzzkR7y3hnY8AD1wXjCnVlHba5.jpg',
      rating: 6.8,
      year: '2023',
    ),
  ];
  final List<Movie> _upcomingMovies = [
    Movie(
      id: '6',
      title: 'Venom: The Last Dance',
      thumbnail:
          'https://image.tmdb.org/t/p/w500/k42Owka8v91trK1qMYwCQCNwJKr.jpg',
      rating: 6.8,
      year: '2024',
    ),
    Movie(
      id: '7',
      title: 'The Wild Robot',
      thumbnail:
          'https://image.tmdb.org/t/p/w500/wTnV3PCVW5O92JMrFvvrRcV39RU.jpg',
      rating: 8.6,
      year: '2024',
    ),
    Movie(
      id: '8',
      title: 'Terrifier 3',
      thumbnail:
          'https://image.tmdb.org/t/p/w500/7NDHoebflLwL1CcgLJ9wZbbDrmV.jpg',
      rating: 7.3,
      year: '2024',
    ),
    Movie(
      id: '9',
      title: 'Smile 2',
      thumbnail:
          'https://image.tmdb.org/t/p/w500/aE85MnPIsSoSs3978Noo16BRsKN.jpg',
      rating: 7.2,
      year: '2024',
    ),
    Movie(
      id: '10',
      title: 'Gladiator II',
      thumbnail:
          'https://image.tmdb.org/t/p/w500/2cxhvwyEwRlysAmRH4iodkvo0z5.jpg',
      rating: 7.0,
      year: '2024',
    ),
  ];
  final List<Movie> _popularTvShows = [
    Movie(
      id: '11',
      title: 'Monster',
      thumbnail:
           'https://image.tmdb.org/t/p/w500/2cxhvwyEwRlysAmRH4iodkvo0z5.jpg',
      rating: 8.7,
      year: '2004',
    ),
    Movie(
      id: '12',
      title: 'Peacemaker',
      thumbnail:
          'https://image.tmdb.org/t/p/w500/hE3LRZAY84fG19a18pzpkZERjTE.jpg',
      rating: 8.3,
      year: '2022',
    ),
    Movie(
      id: '13',
      title: "Grey's Anatomy",
      thumbnail:
          'https://image.tmdb.org/t/p/w500/daSFbrt8QCXV2hSwB0hqYjbj681.jpg',
      rating: 8.2,
      year: '2005',
    ),
    Movie(
      id: '14',
      title: 'Breaking Bad',
      thumbnail:
          'https://image.tmdb.org/t/p/w500/ztkUQFLlC19CCMYHW9o1zWhJRNq.jpg',
      rating: 9.5,
      year: '2008',
    ),
    Movie(
      id: '15',
      title: 'The Last of Us',
      thumbnail:
          'https://image.tmdb.org/t/p/w500/uKvVjHNqB5VmOrdxqAt2F7J78ED.jpg',
      rating: 8.8,
      year: '2023',
    ),
  ];

  List<Movie> get nowPlaying => _nowPlaying;
  List<Movie> get upcomingMovies => _upcomingMovies;
  List<Movie> get popularTvShows => _popularTvShows;
}
